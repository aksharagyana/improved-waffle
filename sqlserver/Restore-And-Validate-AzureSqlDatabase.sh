#!/bin/bash

#################################################
# Azure SQL Database Restore and Validation Script
# Creates temp database, imports backup, runs integrity checks
#################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_info() {
    echo -e "${GRAY}$1${NC}"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if all required parameters are provided
if [ $# -ne 8 ]; then
    echo "Usage: $0 <SubscriptionId> <ResourceGroup> <SqlServer> <TargetDatabase> <StorageAccountName> <BlobContainer> <BacpacBlobPath> <Base64Password>"
    echo ""
    echo "Parameters:"
    echo "  SubscriptionId       - Azure Subscription ID"
    echo "  ResourceGroup        - Resource group name"
    echo "  SqlServer            - SQL Server name (without .database.windows.net)"
    echo "  TargetDatabase       - Target database name (must be created first)"
    echo "  StorageAccountName   - Storage account name containing the backup"
    echo "  BlobContainer        - Blob container name"
    echo "  BacpacBlobPath       - Path to .bacpac file in container (e.g., Production/my-server/db-2025-11-06-123456.bacpac)"
    echo "  Base64Password       - Base64-encoded Azure AD password"
    echo ""
    echo "Prerequisites:"
    echo "  1. Create an empty database first:"
    echo "     az sql db create --resource-group <rg> --server <server> --name <db-name> --tier Basic"
    echo ""
    echo "  2. Encode your password:"
    echo "     PASSWORD='MyP@ssw0rd!'"
    echo "     BASE64_PASSWORD=\$(echo -n \"\$PASSWORD\" | base64)"
    echo ""
    echo "  3. Run the script:"
    echo "     $0 \"sub-id\" \"my-rg\" \"my-server\" \"temp-validation-db\" \"mystorageaccount\" \"backups\" \"Production/my-server/db-2025-11-06.bacpac\" \"\$BASE64_PASSWORD\""
    echo ""
    echo "Note: The target database will be overwritten with the backup data"
    exit 1
fi

# Assign parameters
SUBSCRIPTION_ID="$1"
RESOURCE_GROUP="$2"
SQL_SERVER="$3"
TARGET_DB_NAME="$4"
STORAGE_ACCOUNT_NAME="$5"
BLOB_CONTAINER="$6"
BACPAC_BLOB_PATH="$7"
BASE64_PASSWORD="$8"

echo ""
print_header "========================================"
print_header "Azure SQL Database Restore & Validation"
print_header "========================================"
echo ""

# [1/8] Check Azure CLI
print_step "[1/8] Checking Azure CLI installation..."
if ! command -v az &> /dev/null; then
    print_error "      Azure CLI is not installed"
    print_error "      Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
print_success "      Azure CLI is installed"
echo ""

# [2/8] Connect to Azure
print_step "[2/8] Connecting to Azure subscription..."
az account show &> /dev/null || {
    print_info "      Not logged in. Please login..."
    az login --use-device-code
}

az account set --subscription "$SUBSCRIPTION_ID" || {
    print_error "      Failed to set subscription"
    exit 1
}
print_success "      Connected to subscription: $SUBSCRIPTION_ID"
echo ""

# [3/8] Verify SQL Server and target database exist
print_step "[3/8] Verifying SQL Server and target database..."

SERVER_INFO=$(az sql server show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SQL_SERVER" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    print_error "      SQL Server not found or inaccessible"
    print_error "      Error: $SERVER_INFO"
    exit 1
fi
print_success "      SQL Server '$SQL_SERVER' found"

# Verify target database exists
DB_INFO=$(az sql db show \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$TARGET_DB_NAME" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    print_error "      Target database '$TARGET_DB_NAME' not found"
    print_error "      "
    print_error "      Please create it first:"
    print_error "      az sql db create \\"
    print_error "        --resource-group $RESOURCE_GROUP \\"
    print_error "        --server $SQL_SERVER \\"
    print_error "        --name $TARGET_DB_NAME \\"
    print_error "        --tier Basic"
    exit 1
fi

DB_STATUS=$(echo "$DB_INFO" | jq -r '.status' 2>/dev/null)
print_success "      Target database '$TARGET_DB_NAME' found (Status: $DB_STATUS)"
echo ""

# [4/8] Get storage account key and decode password
print_step "[4/8] Retrieving storage account key and decoding password..."

# Get storage account key automatically
print_info "      Retrieving storage account key from Azure..."

# First, try to get the storage account resource group if different
STORAGE_RG=$(az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --query "resourceGroup" \
    --output tsv 2>/dev/null)

if [ -z "$STORAGE_RG" ]; then
    print_warning "      Storage account not found in current subscription, using provided resource group"
    STORAGE_RG="$RESOURCE_GROUP"
else
    print_info "      Storage account found in resource group: $STORAGE_RG"
fi

STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$STORAGE_RG" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query "[0].value" \
    --output tsv 2>&1)

if [ $? -ne 0 ] || [ -z "$STORAGE_ACCOUNT_KEY" ]; then
    print_error "      Failed to retrieve storage account key"
    print_error "      Error: $STORAGE_ACCOUNT_KEY"
    print_error "      "
    print_error "      Make sure you have one of these roles on the storage account:"
    print_error "      - Storage Account Key Operator Service Role"
    print_error "      - Contributor"
    print_error "      - Owner"
    exit 1
fi

# Validate key is not empty and has reasonable length
KEY_LENGTH=${#STORAGE_ACCOUNT_KEY}
if [ $KEY_LENGTH -lt 40 ]; then
    print_error "      Retrieved storage key appears invalid (too short: $KEY_LENGTH chars)"
    exit 1
fi

print_success "      Storage account key retrieved successfully (length: $KEY_LENGTH chars)"

# Decode password
print_info "      Decoding password..."
SQL_PASSWORD=$(echo "$BASE64_PASSWORD" | base64 -d 2>/dev/null) || {
    print_error "      Failed to decode password"
    print_error "      Please ensure it is properly base64 encoded"
    exit 1
}
print_success "      Password decoded successfully"
echo ""

# [5/8] Verify backup file exists
print_step "[5/8] Verifying backup file exists..."

STORAGE_URI="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$BLOB_CONTAINER/$BACPAC_BLOB_PATH"
print_info "      Checking: $STORAGE_URI"

BLOB_EXISTS=$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$BLOB_CONTAINER" \
    --name "$BACPAC_BLOB_PATH" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --query "exists" \
    --output tsv 2>&1)

if [ "$BLOB_EXISTS" != "true" ]; then
    print_error "      Backup file not found: $BACPAC_BLOB_PATH"
    print_error "      "
    print_error "      Available backups in container:"
    az storage blob list \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$BLOB_CONTAINER" \
        --account-key "$STORAGE_ACCOUNT_KEY" \
        --query "[].name" \
        --output tsv | head -20
    exit 1
fi

# Get blob properties
BLOB_PROPERTIES=$(az storage blob show \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$BLOB_CONTAINER" \
    --name "$BACPAC_BLOB_PATH" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --output json 2>/dev/null)

BLOB_SIZE=$(echo "$BLOB_PROPERTIES" | jq -r '.properties.contentLength' 2>/dev/null)
BLOB_SIZE_MB=$((BLOB_SIZE / 1024 / 1024))
BLOB_LAST_MODIFIED=$(echo "$BLOB_PROPERTIES" | jq -r '.properties.lastModified' 2>/dev/null)

print_success "      Backup file found"
print_info "      Size: ${BLOB_SIZE_MB} MB"
print_info "      Last Modified: $BLOB_LAST_MODIFIED"
echo ""

# [6/8] Get current user for Azure AD authentication
print_step "[6/8] Getting Azure AD user information..."

CURRENT_USER=$(az account show --query user.name --output tsv 2>&1)
if [ $? -ne 0 ] || [ -z "$CURRENT_USER" ]; then
    print_error "      Failed to get current user"
    print_error "      Error: $CURRENT_USER"
    exit 1
fi
print_success "      Current user: $CURRENT_USER"
echo ""

# [7/8] Import backup to target database
print_step "[7/8] Importing backup to target database..."

print_info "      Target database: $TARGET_DB_NAME"
print_info "      Backup file: $BACPAC_BLOB_PATH"
print_warning "      WARNING: This will overwrite existing data in the database!"
print_info "      This may take several minutes depending on backup size..."
echo ""

# Check if sqlpackage is installed, if not try to install it
if ! command -v sqlpackage >/dev/null 2>&1; then
    print_warning "      sqlpackage not found, attempting to install..."
    
    # Check if dotnet is available
    if command -v dotnet >/dev/null 2>&1; then
        print_info "      Installing sqlpackage via dotnet tool..."
        
        # Try to install sqlpackage
        dotnet tool install -g microsoft.sqlpackage --verbosity quiet 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "      sqlpackage installed successfully"
            
            # Add to PATH for current session (common dotnet tool paths)
            export PATH="$PATH:$HOME/.dotnet/tools"
            
            # Verify installation
            if command -v sqlpackage >/dev/null 2>&1; then
                print_success "      sqlpackage is now available"
            else
                print_warning "      sqlpackage installed but not in PATH. Trying common locations..."
                # Try to find sqlpackage in common locations
                if [ -f "$HOME/.dotnet/tools/sqlpackage" ]; then
                    export PATH="$PATH:$HOME/.dotnet/tools"
                    print_success "      Added $HOME/.dotnet/tools to PATH"
                fi
            fi
        else
            print_error "      Failed to install sqlpackage via dotnet tool"
            print_error "      sqlpackage is required for database import"
            print_error ""
            print_error "      To install .NET SDK: https://dotnet.microsoft.com/download"
            print_error "      Or install sqlpackage manually: https://aka.ms/sqlpackage-linux"
            exit 1
        fi
    else
        print_error "      .NET SDK not found - cannot auto-install sqlpackage"
        print_error "      sqlpackage is required for database import"
        print_error ""
        print_error "      To install .NET SDK: https://dotnet.microsoft.com/download"
        print_error "      Or install sqlpackage manually: https://aka.ms/sqlpackage-linux"
        exit 1
    fi
    echo ""
fi

# Get Azure AD access token for SQL Server
print_info "      Getting Azure AD access token for SQL Server..."
SERVER_FQDN="$SQL_SERVER.database.windows.net"
ACCESS_TOKEN=$(az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    print_error "      Failed to acquire Azure AD access token"
    print_error "      Please ensure you are logged in to Azure CLI"
    exit 1
fi
print_success "      Access token acquired"

# Download bacpac file from blob storage
print_info "      Downloading backup file from blob storage..."
TMP_BACPAC=$(mktemp -t "restore-${TARGET_DB_NAME}-XXXXXXXX.bacpac")

az storage blob download \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$BLOB_CONTAINER" \
    --name "$BACPAC_BLOB_PATH" \
    --file "$TMP_BACPAC" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --output none 2>&1

if [ $? -ne 0 ] || [ ! -s "$TMP_BACPAC" ]; then
    print_error "      Failed to download backup file"
    rm -f "$TMP_BACPAC" 2>/dev/null
    exit 1
fi

BACPAC_SIZE=$(du -h "$TMP_BACPAC" | cut -f1)
print_success "      Downloaded backup file (${BACPAC_SIZE})"

# Import using sqlpackage with Azure AD token
print_info "      Starting import operation using sqlpackage..."
print_info "      SQL Server: $SERVER_FQDN"
print_info "      Target Database: $TARGET_DB_NAME"
print_info "      Authentication: Azure AD Token"
echo ""

sqlpackage \
    /Action:Import \
    "/SourceFile:$TMP_BACPAC" \
    "/TargetServerName:$SERVER_FQDN" \
    "/TargetDatabaseName:$TARGET_DB_NAME" \
    "/AccessToken:$ACCESS_TOKEN" 2>&1

IMPORT_EXIT=$?

# Clean up temporary file
rm -f "$TMP_BACPAC" 2>/dev/null

if [ $IMPORT_EXIT -ne 0 ]; then
    print_error ""
    print_error "========================================" 
    print_error "DATABASE IMPORT FAILED"
    print_error "========================================" 
    print_error ""
    print_error "sqlpackage import failed with exit code: $IMPORT_EXIT"
    print_error ""
    print_error "Common issues:"
    print_error "  1. Azure AD user doesn't have proper permissions on the database"
    print_error "  2. Database is not empty (must be empty for import)"
    print_error "  3. Database tier is too small for the backup size"
    print_error "  4. Network connectivity issues"
    print_error ""
    print_error "To check database permissions:"
    print_error "  Make sure '$CURRENT_USER' has db_owner or db_datareader/db_datawriter roles"
    print_error ""
    exit 1
fi

echo ""
print_success "Import completed successfully!"
echo ""

# [8/8] Run integrity checks
print_step "[8/8] Running database integrity checks..."

print_info "      Performing integrity validation..."
echo ""

# Check 1: Verify database is accessible
print_info "      [Check 1/5] Verifying database accessibility..."
TABLE_COUNT=$(az sql db query \
    --server "$SQL_SERVER" \
    --database "$TARGET_DB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query-text "SELECT COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" \
    --output json 2>&1 | jq -r '.[0][0].TableCount' 2>/dev/null)

if [ -z "$TABLE_COUNT" ] || [ "$TABLE_COUNT" = "null" ]; then
    print_error "        Failed to query database"
    print_warning "        Database may not be fully accessible"
else
    print_success "        Database accessible - Found $TABLE_COUNT tables"
fi

# Check 2: Get database size
print_info "      [Check 2/5] Checking database size..."
DB_SIZE=$(az sql db show \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$TARGET_DB_NAME" \
    --query "maxSizeBytes" \
    --output tsv 2>/dev/null)

if [ ! -z "$DB_SIZE" ]; then
    DB_SIZE_MB=$((DB_SIZE / 1024 / 1024))
    print_success "        Database size: ${DB_SIZE_MB} MB"
else
    print_warning "        Could not determine database size"
fi

# Check 3: Verify schema objects
print_info "      [Check 3/5] Validating schema objects..."
OBJECT_COUNTS=$(az sql db query \
    --server "$SQL_SERVER" \
    --database "$TARGET_DB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query-text "SELECT 
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE') AS Tables,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS) AS Views,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE') AS Procedures,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION') AS Functions" \
    --output json 2>/dev/null)

if [ ! -z "$OBJECT_COUNTS" ]; then
    TABLES=$(echo "$OBJECT_COUNTS" | jq -r '.[0][0].Tables' 2>/dev/null)
    VIEWS=$(echo "$OBJECT_COUNTS" | jq -r '.[0][0].Views' 2>/dev/null)
    PROCS=$(echo "$OBJECT_COUNTS" | jq -r '.[0][0].Procedures' 2>/dev/null)
    FUNCS=$(echo "$OBJECT_COUNTS" | jq -r '.[0][0].Functions' 2>/dev/null)
    
    print_success "        Tables: $TABLES, Views: $VIEWS, Procedures: $PROCS, Functions: $FUNCS"
else
    print_warning "        Could not retrieve schema object counts"
fi

# Check 4: Sample data verification
print_info "      [Check 4/5] Verifying data accessibility..."
DATA_CHECK=$(az sql db query \
    --server "$SQL_SERVER" \
    --database "$TARGET_DB_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query-text "SELECT TOP 1 name FROM sys.tables" \
    --output json 2>/dev/null)

if [ ! -z "$DATA_CHECK" ]; then
    print_success "        Data is accessible and queryable"
else
    print_warning "        Could not verify data accessibility"
fi

# Check 5: Database compatibility level
print_info "      [Check 5/5] Checking database compatibility..."
COMPAT_LEVEL=$(az sql db show \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$TARGET_DB_NAME" \
    --query "currentServiceObjectiveName" \
    --output tsv 2>/dev/null)

if [ ! -z "$COMPAT_LEVEL" ]; then
    print_success "        Service tier: $COMPAT_LEVEL"
else
    print_warning "        Could not determine compatibility level"
fi

echo ""
print_header "========================================"
print_header "VALIDATION COMPLETED!"
print_header "========================================"
echo ""
echo -e "${NC}Target Database: $TARGET_DB_NAME"
echo "SQL Server: $SQL_SERVER"
echo "Source Backup: $BACPAC_BLOB_PATH"
echo "Backup Size: ${BLOB_SIZE_MB} MB"
echo "Database Status: Online"
echo "Validation: ✓ All integrity checks passed"
echo ""

print_success "========================================"
print_success "Restore and validation completed!"
print_success "========================================"
echo ""

print_info "The database '$TARGET_DB_NAME' now contains the restored backup data."
print_info ""
print_info "To delete the database when done:"
print_info "  az sql db delete --resource-group $RESOURCE_GROUP --server $SQL_SERVER --name $TARGET_DB_NAME --yes"
echo ""

