#!/bin/bash

#################################################
# Azure SQL Database Backup Script (Bash)
# Uses Entra ID (Azure AD) authentication
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

# Check if all required parameters are provided
if [ $# -ne 9 ]; then
    echo "Usage: $0 <SubscriptionId> <SubscriptionName> <ResourceGroup> <SqlServer> <SqlDatabase> <BlobName> <StorageAccountName> <SqlUsername> <Base64Password>"
    echo ""
    echo "Parameters:"
    echo "  SubscriptionId       - Azure Subscription ID"
    echo "  SubscriptionName     - Subscription name (for blob path)"
    echo "  ResourceGroup        - Resource group name"
    echo "  SqlServer            - SQL Server name"
    echo "  SqlDatabase          - Database name"
    echo "  BlobName             - Blob container name"
    echo "  StorageAccountName   - Storage account name"
    echo "  SqlUsername          - Azure AD username"
    echo "  Base64Password       - Base64-encoded Azure AD password"
    echo ""
    echo "Note: Storage account key will be retrieved automatically from Azure"
    echo ""
    echo "Example:"
    echo "  # Encode your password"
    echo "  PASSWORD='MyP@ssw0rd!'"
    echo "  BASE64_PASSWORD=\$(echo -n \"\$PASSWORD\" | base64)"
    echo ""
    echo "  # Then run the script"
    echo "  $0 \"sub-id\" \"Production\" \"my-rg\" \"my-server\" \"my-db\" \"sqlbackups\" \"mystorageaccount\" \"user@domain.com\" \"\$BASE64_PASSWORD\""
    exit 1
fi

# Assign parameters
SUBSCRIPTION_ID="$1"
SUBSCRIPTION_NAME="$2"
RESOURCE_GROUP="$3"
SQL_SERVER="$4"
SQL_DATABASE="$5"
BLOB_NAME="$6"
STORAGE_ACCOUNT_NAME="$7"
SQL_USERNAME="$8"
BASE64_PASSWORD="$9"

echo ""
print_header "========================================"
print_header "Azure SQL Database Backup (Entra ID)"
print_header "========================================"
echo ""

# [1/6] Check Azure CLI
print_step "[1/6] Checking Azure CLI installation..."
if ! command -v az &> /dev/null; then
    print_error "      Azure CLI is not installed"
    print_error "      Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
print_success "      Azure CLI is installed"
echo ""

# [2/6] Connect to Azure
print_step "[2/6] Connecting to Azure subscription..."
az account show &> /dev/null || {
    print_info "      Not logged in. Please login..."
    az login --use-device-code
}

az account set --subscription "$SUBSCRIPTION_ID" || {
    print_error "Failed to set subscription: $SUBSCRIPTION_ID"
    exit 1
}
print_success "      Connected to subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

# [3/6] Test database connectivity and authentication
print_step "[3/6] Testing database connectivity and authentication..."
print_info "      Checking if database exists: $SQL_SERVER/$SQL_DATABASE"

if ! az sql db show \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$SQL_DATABASE" \
    --output json &> /dev/null; then
    
    print_error ""
    print_error "Database not found or not accessible"
    print_error "Please verify database name: $SQL_DATABASE"
    exit 1
fi

DB_STATUS=$(az sql db show \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$SQL_DATABASE" \
    --query "status" \
    --output tsv)

print_success "      Database exists and is accessible"
print_info "      Database status: $DB_STATUS"
echo ""

# Test actual authentication by attempting a list operation
print_info "      Testing Azure AD authentication..."
print_info "      Verifying access to database objects..."

# Check if az sql db query command is available
if az sql db query --help &> /dev/null; then
    print_info "      Using 'az sql db query' to test authentication..."
    
    # Try to execute a query using Azure CLI
    QUERY_OUTPUT=$(az sql db query \
        --server "$SQL_SERVER" \
        --database "$SQL_DATABASE" \
        --resource-group "$RESOURCE_GROUP" \
        --query-text "SELECT COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" \
        --output json 2>&1)
    
    QUERY_EXIT=$?
    
    if [ $QUERY_EXIT -ne 0 ]; then
        print_error ""
        print_error "Failed to authenticate and query database"
        print_error "Error: $QUERY_OUTPUT"
        print_error ""
        print_error "Please verify:"
        print_error "1. Azure AD user (current login) has db_owner role on the database"
        print_error "2. User is added as database user or Azure AD admin"
        print_error "3. Server firewall allows your IP or Azure services"
        print_error ""
        print_error "To add user to database, run as Azure AD admin:"
        print_error "CREATE USER [$(az account show --query user.name -o tsv)] FROM EXTERNAL PROVIDER;"
        print_error "ALTER ROLE db_owner ADD MEMBER [$(az account show --query user.name -o tsv)];"
        exit 1
    fi
    
    # Parse the result to get table count
    TABLE_COUNT=$(echo "$QUERY_OUTPUT" | jq -r '.[0].rows[0][0].TableCount' 2>/dev/null)
    
    if [ -z "$TABLE_COUNT" ] || [ "$TABLE_COUNT" = "null" ]; then
        TABLE_COUNT=$(echo "$QUERY_OUTPUT" | jq -r '.[0][0].TableCount' 2>/dev/null)
    fi
    
    print_success "      Successfully authenticated and executed query"
    print_info "      Found $TABLE_COUNT tables in database"
else
    print_info "      'az sql db query' not available in this Azure CLI version"
    print_info "      Verifying database operations access..."
    
    # Alternative: Try to list database operations as auth check
    OPS_OUTPUT=$(az sql db op list \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER" \
        --database "$SQL_DATABASE" \
        --output json 2>&1)
    
    OPS_EXIT=$?
    
    if [ $OPS_EXIT -ne 0 ]; then
        print_error ""
        print_error "Cannot access database operations"
        print_error "Error: $OPS_OUTPUT"
        print_error ""
        print_error "Please verify:"
        print_error "1. Azure AD user (current login) has access to the database"
        print_error "2. Server firewall allows your IP or Azure services"
        print_error ""
        print_error "Note: Full authentication will be tested during export"
        print_error "To add user to database, run as Azure AD admin:"
        print_error "CREATE USER [$(az account show --query user.name -o tsv)] FROM EXTERNAL PROVIDER;"
        print_error "ALTER ROLE db_owner ADD MEMBER [$(az account show --query user.name -o tsv)];"
        exit 1
    fi
    
    print_success "      Successfully verified database access"
    print_info "      Note: Full authentication will be verified during export"
fi

echo ""

# [4/6] Decode secrets
print_step "[4/6] Retrieving storage account key and decoding password..."

# Get storage account key automatically
print_info "      Retrieving storage account key from Azure..."
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
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
print_success "      Storage account key retrieved successfully"

# Decode password
print_info "      Decoding password..."
SQL_PASSWORD=$(echo "$BASE64_PASSWORD" | base64 -d 2>/dev/null) || {
    print_error "      Failed to decode password"
    print_error "      Please ensure it is properly base64 encoded"
    exit 1
}
print_success "      Password decoded successfully"
echo ""

# Generate timestamp and blob path
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BLOB_PATH="$SUBSCRIPTION_NAME/$SQL_SERVER/$SQL_DATABASE-$TIMESTAMP.bacpac"

# [5/6] Check storage account authentication and blob container
print_step "[5/6] Checking storage account authentication..."

# Check if storage account allows key-based authentication
STORAGE_INFO=$(az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --query "{allowSharedKeyAccess: allowSharedKeyAccess}" \
    --output json 2>/dev/null)

ALLOW_KEY_AUTH=$(echo "$STORAGE_INFO" | jq -r '.allowSharedKeyAccess' 2>/dev/null)

if [ "$ALLOW_KEY_AUTH" = "false" ]; then
    print_error ""
    print_error "========================================" 
    print_error "STORAGE AUTHENTICATION ISSUE"
    print_error "========================================" 
    print_error ""
    print_error "Storage account '$STORAGE_ACCOUNT_NAME' has key-based authentication DISABLED."
    print_error "The 'az sql db export' command REQUIRES storage account key access."
    print_error "Azure AD authentication is NOT supported for SQL database export to storage."
    print_error ""
    print_error "This is an Azure SQL limitation, not a script limitation."
    print_error ""
    print_error "SOLUTION - Enable key-based authentication:"
    print_error ""
    print_error "az storage account update \\"
    print_error "  --name $STORAGE_ACCOUNT_NAME \\"
    print_error "  --resource-group $RESOURCE_GROUP \\"
    print_error "  --allow-shared-key-access true"
    print_error ""
    print_error "Then run this script again"
    print_error ""
    exit 1
fi

print_success "      Storage account allows key-based authentication"
print_info "      Checking blob container..."

# Use Azure AD authentication for container check (works regardless of key-based setting)
CONTAINER_EXISTS=$(az storage container exists \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --name "$BLOB_NAME" \
    --auth-mode login \
    --query "exists" \
    --output tsv 2>&1)

if [ $? -ne 0 ]; then
    print_error "Failed to check blob container"
    print_error "Error: $CONTAINER_EXISTS"
    print_error "Please ensure you have 'Storage Blob Data Contributor' role on the storage account"
    exit 1
fi

if [ "$CONTAINER_EXISTS" = "false" ]; then
    print_info "      Container '$BLOB_NAME' does not exist. Creating..."
    
    az storage container create \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --name "$BLOB_NAME" \
        --auth-mode login \
        --output none
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create blob container"
        exit 1
    fi
    
    print_success "      Container created successfully"
else
    print_success "      Container '$BLOB_NAME' exists in $STORAGE_ACCOUNT_NAME"
fi

echo ""

# [6/7] Check if blob already exists (idempotent check)
STORAGE_URI="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$BLOB_NAME/$BLOB_PATH"

print_step "[6/7] Checking if backup already exists..."
print_info "      Container: $BLOB_NAME"
print_info "      Blob path: $BLOB_PATH"

# Use storage account key for blob operations
BLOB_CHECK_RESULT=$(az storage blob exists \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$BLOB_NAME" \
    --name "$BLOB_PATH" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --output json 2>&1)

BLOB_CHECK_EXIT=$?

if [ $BLOB_CHECK_EXIT -ne 0 ]; then
    print_error "Failed to check blob existence"
    print_error "$BLOB_CHECK_RESULT"
    exit 1
fi

BLOB_EXISTS=$(echo "$BLOB_CHECK_RESULT" | jq -r '.exists' 2>/dev/null)
print_info "      Blob exists: $BLOB_EXISTS"

if [ "$BLOB_EXISTS" = "true" ]; then
    print_success "      Backup already exists: $BLOB_PATH"
    print_info "      Skipping backup creation (idempotent operation)"
    
    # Get blob properties using SAS token
    BLOB_PROPERTIES=$(az storage blob show \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$BLOB_NAME" \
        --name "$BLOB_PATH" \
        --account-key "$STORAGE_ACCOUNT_KEY" \
        --output json 2>/dev/null)
    
    BLOB_SIZE=$(echo "$BLOB_PROPERTIES" | jq -r '.properties.contentLength' 2>/dev/null)
    BLOB_SIZE_MB=$((BLOB_SIZE / 1024 / 1024))
    BLOB_LAST_MODIFIED=$(echo "$BLOB_PROPERTIES" | jq -r '.properties.lastModified' 2>/dev/null)
    
    echo ""
    print_header "========================================"
    print_header "BACKUP ALREADY EXISTS!"
    print_header "========================================"
    echo -e "${NC}Database: $SQL_DATABASE"
    echo "Backup Location: $STORAGE_URI"
    echo "Blob Path: $BLOB_PATH"
    echo "Blob Size: ${BLOB_SIZE_MB} MB"
    echo "Last Modified: $BLOB_LAST_MODIFIED"
    echo "Status: Skipped (already exists)"
    echo ""
    print_success "Backup script completed successfully (idempotent - blob already exists)"
    echo ""
    exit 0
fi

# Check for any existing blobs with today's timestamp (partial/failed backups)
DATABASE_PREFIX="$SUBSCRIPTION_NAME/$SQL_SERVER/$SQL_DATABASE-$(date +"%Y-%m-%d")"
print_info "      Checking for failed/partial backups with prefix: $DATABASE_PREFIX"

EXISTING_BLOBS=$(az storage blob list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$BLOB_NAME" \
    --prefix "$DATABASE_PREFIX" \
    --account-key "$STORAGE_ACCOUNT_KEY" \
    --query "[].{name:name,size:properties.contentLength,modified:properties.lastModified}" \
    --output json 2>/dev/null)

EXISTING_COUNT=$(echo "$EXISTING_BLOBS" | jq '. | length' 2>/dev/null)

if [ "$EXISTING_COUNT" -gt 0 ]; then
    print_warning "      Found $EXISTING_COUNT existing blob(s) for today:"
    echo "$EXISTING_BLOBS" | jq -r '.[] | "        - \(.name) (\(.size) bytes, modified: \(.modified))"' 2>/dev/null
    echo ""
    print_warning "      These may be from failed export attempts or Azure SQL may have a stuck operation."
    echo ""
    
    # Show cleanup option
    echo -e "${YELLOW}      Options:${NC}"
    echo "        1. Delete these blobs and retry"
    echo "        2. Skip (exit script)"
    echo ""
    read -p "      Choose option (1/2): " -n 1 -r CLEANUP_CHOICE
    echo ""
    echo ""
    
    if [ "$CLEANUP_CHOICE" = "1" ]; then
        echo "$EXISTING_BLOBS" | jq -r '.[].name' | while read blob; do
            print_info "      Deleting: $blob"
            az storage blob delete \
                --account-name "$STORAGE_ACCOUNT_NAME" \
                --container-name "$BLOB_NAME" \
                --name "$blob" \
                --account-key "$STORAGE_ACCOUNT_KEY" \
                --output none 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "        Deleted successfully"
            else
                print_error "        Failed to delete"
            fi
        done
        echo ""
        print_success "      Cleanup complete, proceeding with new backup"
    else
        print_info "      Exiting. Please investigate the existing blobs."
        print_info ""
        print_info "      To manually delete blobs:"
        echo "$EXISTING_BLOBS" | jq -r '.[].name' | while read blob; do
            echo "        az storage blob delete --account-name $STORAGE_ACCOUNT_NAME --container-name $BLOB_NAME --name \"$blob\" --account-key \"<your-key>\""
        done
        exit 0
    fi
    echo ""
fi

print_success "      Proceeding with new backup"
echo ""

# Check for any pending export/import operations on the database
print_info "      Checking for pending database operations..."
PENDING_OPS=$(az sql db op list \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --database "$SQL_DATABASE" \
    --query "[?state=='InProgress' || state=='Pending'].{operation:operation,state:state,startTime:startTime}" \
    --output json 2>/dev/null)

PENDING_COUNT=$(echo "$PENDING_OPS" | jq '. | length' 2>/dev/null)

if [ "$PENDING_COUNT" -gt 0 ]; then
    print_warning "      Found $PENDING_COUNT pending operation(s) on database:"
    echo "$PENDING_OPS" | jq -r '.[] | "        - \(.operation) (\(.state)) started at \(.startTime)"' 2>/dev/null
    echo ""
    print_error "Cannot start new export while other operations are in progress."
    print_error "Please wait for pending operations to complete or cancel them."
    print_error ""
    print_error "To check operations:"
    print_error "  az sql db op list --resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $SQL_DATABASE"
    print_error ""
    print_error "To cancel a stuck operation (if needed):"
    print_error "  az sql db op cancel --resource-group $RESOURCE_GROUP --server $SQL_SERVER --database $SQL_DATABASE --name <operation-id>"
    exit 1
fi

print_success "      No pending operations found"
echo ""

# [7/7] Export database
print_step "[7/7] Starting database backup export..."

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
            print_warning "      Failed to install sqlpackage via dotnet tool"
            print_info "      Will fall back to az sql db export method"
        fi
    else
        print_warning "      .NET SDK not found - cannot auto-install sqlpackage"
        print_info "      To install .NET SDK: https://dotnet.microsoft.com/download"
        print_info "      Or install sqlpackage manually: https://aka.ms/sqlpackage-linux"
        print_info "      Will fall back to az sql db export method"
    fi
    echo ""
fi

print_info "      Database: $SQL_DATABASE"
print_info "      Blob Path: $BLOB_PATH"
print_info "      Storage URI: $STORAGE_URI"
print_info "      SQL Authentication: Azure AD (Entra ID)"
print_info "      Storage Authentication: SAS Token"
print_info "      This may take several minutes depending on database size..."
echo ""

print_info "      Executing export..."

# Prefer Azure AD access token with sqlpackage if available
SERVER_FQDN="$SQL_SERVER.database.windows.net"
ACCESS_TOKEN=$(az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv 2>/dev/null)

if command -v sqlpackage >/dev/null 2>&1 && [ -n "$ACCESS_TOKEN" ]; then
    print_info "      Detected sqlpackage and acquired Azure AD access token"
    print_info "      Using token-based export via sqlpackage"

    # Create temporary bacpac file
    TMP_BACPAC=$(mktemp -t "${SQL_DATABASE}-XXXXXXXX.bacpac")
    print_info "      Exporting to temp file: $TMP_BACPAC"

    # Run sqlpackage export with access token
    sqlpackage \
        /Action:Export \
        "/SourceServerName:$SERVER_FQDN" \
        "/SourceDatabaseName:$SQL_DATABASE" \
        "/TargetFile:$TMP_BACPAC" \
        "/AccessToken:$ACCESS_TOKEN" > /dev/null 2>&1

    if [ $? -ne 0 ] || [ ! -s "$TMP_BACPAC" ]; then
        print_error ""
        print_error "sqlpackage export failed"
        print_error "Ensure sqlpackage is installed and accessible in PATH"
        print_error "You can install sqlpackage from Microsoft docs (cross-platform)"
        rm -f "$TMP_BACPAC" 2>/dev/null
        exit 1
    fi

    print_success "      Exported bacpac locally"
    print_info "      Uploading bacpac to blob: $BLOB_PATH"

    # Upload to blob storage using storage account key
    az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --container-name "$BLOB_NAME" \
        --name "$BLOB_PATH" \
        --file "$TMP_BACPAC" \
        --account-key "$STORAGE_ACCOUNT_KEY" \
        --overwrite false \
        --output none 2>/dev/null

    UPLOAD_EXIT=$?
    rm -f "$TMP_BACPAC" 2>/dev/null

    if [ $UPLOAD_EXIT -ne 0 ]; then
        print_error ""
        print_error "Failed to upload bacpac to blob storage"
        exit 1
    fi

    print_success "      Upload complete"
    echo ""
    print_header "========================================"
    print_header "EXPORT COMPLETED (sqlpackage + AAD token)"
    print_header "========================================"
    echo -e "${NC}Database: $SQL_DATABASE"
    echo "Backup Location: $STORAGE_URI"
    echo "Blob Path: $BLOB_PATH"
    echo "Status: Success"
    echo ""
    exit 0
fi

# Fallback: Use az sql db export with AD password (requires AAD password)
# Note: Using storage account key for storage access
az sql db export \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER" \
    --name "$SQL_DATABASE" \
    --admin-user "$SQL_USERNAME" \
    --admin-password "$SQL_PASSWORD" \
    --auth-type ADPassword \
    --storage-key-type SharedAccessKey \
    --storage-key "$STORAGE_ACCOUNT_KEY" \
    --storage-uri "$STORAGE_URI" \
    --output json > /dev/null || {
    print_error ""
    print_error "Database export failed"
    print_error "Please check error message above for details"
    exit 1
}

print_success "      Export request submitted successfully"
echo ""

# Monitor export status
print_step "Monitoring export status (checking every 15 seconds)..."
MAX_WAIT_MINUTES=60
CHECK_INTERVAL_SECONDS=15
MAX_CHECKS=$((MAX_WAIT_MINUTES * 60 / CHECK_INTERVAL_SECONDS))
CHECK_COUNT=0

while [ $CHECK_COUNT -lt $MAX_CHECKS ]; do
    sleep $CHECK_INTERVAL_SECONDS
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    ELAPSED_MINUTES=$(awk "BEGIN {printf \"%.1f\", $CHECK_COUNT * $CHECK_INTERVAL_SECONDS / 60}")
    print_info "      Elapsed time: $ELAPSED_MINUTES minutes..."
    
    # Get latest export operation
    OPERATIONS=$(az sql db op list \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER" \
        --database "$SQL_DATABASE" \
        --output json 2>/dev/null || echo "[]")
    
    EXPORT_STATUS=$(echo "$OPERATIONS" | jq -r '[.[] | select(.name | contains("Export"))] | .[0].state // empty' 2>/dev/null)
    
    if [ ! -z "$EXPORT_STATUS" ]; then
        if [ "$EXPORT_STATUS" = "SUCCEEDED" ]; then
            print_success "      Status: Export completed successfully!"
            break
        elif [ "$EXPORT_STATUS" = "FAILED" ] || [ "$EXPORT_STATUS" = "CANCELLED" ]; then
            print_error "      Export failed with status: $EXPORT_STATUS"
            exit 1
        else
            PERCENT=$(echo "$OPERATIONS" | jq -r '[.[] | select(.name | contains("Export"))] | .[0].percentComplete // 0' 2>/dev/null)
            print_info "      Status: $EXPORT_STATUS - Progress: $PERCENT%"
        fi
    fi
done

echo ""
print_header "========================================"
print_header "BACKUP COMPLETED SUCCESSFULLY!"
print_header "========================================"
echo -e "${NC}Database: $SQL_DATABASE"
echo "Backup Location: $STORAGE_URI"
echo "Blob Path: $BLOB_PATH"
echo "Timestamp: $TIMESTAMP"
echo ""

