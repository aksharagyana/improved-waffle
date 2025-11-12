#!/bin/bash

# Azure App Registration Access Control Configuration Script
# This script helps configure user access and API permissions for your OAuth app registration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure App Registration Access Control Configuration ===${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}You are not logged in to Azure CLI. Please log in first.${NC}"
    az login
fi

# Get current subscription info
TENANT_ID=$(az account show --query tenantId --output tsv)
echo "Tenant ID: $TENANT_ID"
echo ""

# Function to list existing app registrations
list_app_registrations() {
    echo -e "${BLUE}Available App Registrations:${NC}"
    az ad app list --query "[].{DisplayName:displayName, AppId:appId}" --output table
    echo ""
}

# Function to configure user assignment
configure_user_assignment() {
    local app_id=$1
    
    echo -e "${BLUE}=== User Assignment Configuration ===${NC}"
    echo ""
    echo "There are several ways to control user access:"
    echo ""
    echo "1. ${YELLOW}Assignment Required${NC} - Only assigned users can access"
    echo "2. ${YELLOW}Assignment Optional${NC} - All users can access (default)"
    echo "3. ${YELLOW}Specific Users/Groups${NC} - Assign specific users or groups"
    echo ""
    
    read -p "Do you want to require user assignment? (y/n): " require_assignment
    
    if [[ $require_assignment =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Setting assignment required...${NC}"
        az ad sp update --id "$app_id" --set appRoleAssignmentRequired=true
        echo -e "${GREEN}✓ Assignment required enabled${NC}"
        echo ""
        
        echo -e "${BLUE}Available users in your tenant:${NC}"
        az ad user list --query "[].{DisplayName:displayName, UserPrincipalName:userPrincipalName}" --output table --max-items 10
        echo ""
        
        read -p "Enter user principal name to assign (or press Enter to skip): " user_principal_name
        
        if [ ! -z "$user_principal_name" ]; then
            echo -e "${BLUE}Assigning user to app registration...${NC}"
            # Get the service principal ID
            sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
            # Get the user ID
            user_id=$(az ad user show --id "$user_principal_name" --query id --output tsv)
            
            # Assign user to the app
            az rest --method POST \
                --uri "https://graph.microsoft.com/v1.0/users/$user_id/appRoleAssignments" \
                --body "{\"principalId\":\"$user_id\",\"resourceId\":\"$sp_id\",\"appRoleId\":\"00000000-0000-0000-0000-000000000000\"}" \
                --headers "Content-Type=application/json"
            
            echo -e "${GREEN}✓ User assigned successfully${NC}"
        fi
    else
        echo -e "${BLUE}Setting assignment optional...${NC}"
        az ad sp update --id "$app_id" --set appRoleAssignmentRequired=false
        echo -e "${GREEN}✓ Assignment optional enabled (all users can access)${NC}"
    fi
    echo ""
}

# Function to configure API permissions
configure_api_permissions() {
    local app_id=$1
    
    echo -e "${BLUE}=== API Permissions Configuration ===${NC}"
    echo ""
    echo "Available permission types:"
    echo "1. Microsoft Graph permissions (for user profile, groups, etc.)"
    echo "2. Azure AD permissions (for directory access)"
    echo "3. Custom API permissions (if you have a custom API)"
    echo ""
    
    read -p "Do you want to add Microsoft Graph permissions? (y/n): " add_graph_perms
    
    if [[ $add_graph_perms =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Adding Microsoft Graph permissions...${NC}"
        
        # Add common permissions
        echo "Adding User.Read permission..."
        az ad app permission add --id "$app_id" --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
        
        echo "Adding Group.Read.All permission..."
        az ad app permission add --id "$app_id" --api 00000003-0000-0000-c000-000000000000 --api-permissions 5f8c59db-677d-491c-a6c4-0be6a6de8fcf=Scope
        
        echo -e "${GREEN}✓ Microsoft Graph permissions added${NC}"
        echo ""
        
        echo -e "${YELLOW}Note: Admin consent may be required for some permissions${NC}"
        read -p "Do you want to grant admin consent for these permissions? (y/n): " grant_consent
        
        if [[ $grant_consent =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Granting admin consent...${NC}"
            az ad app permission admin-consent --id "$app_id"
            echo -e "${GREEN}✓ Admin consent granted${NC}"
        fi
    fi
    echo ""
}

# Function to create custom app roles
create_custom_app_roles() {
    local app_id=$1
    
    echo -e "${BLUE}=== Custom App Roles Configuration ===${NC}"
    echo ""
    echo "Custom app roles allow you to define specific permissions within your application."
    echo "For example: 'Admin', 'User', 'ReadOnly', etc."
    echo ""
    
    read -p "Do you want to create custom app roles? (y/n): " create_roles
    
    if [[ $create_roles =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Creating custom app roles...${NC}"
        
        # Create a manifest with custom roles
        cat > app-roles-manifest.json << 'EOF'
{
  "appRoles": [
    {
      "allowedMemberTypes": ["User"],
      "description": "Admin users can perform all operations",
      "displayName": "Admin",
      "id": "00000000-0000-0000-0000-000000000001",
      "isEnabled": true,
      "value": "Admin"
    },
    {
      "allowedMemberTypes": ["User"],
      "description": "Regular users can perform basic operations",
      "displayName": "User",
      "id": "00000000-0000-0000-0000-000000000002",
      "isEnabled": true,
      "value": "User"
    },
    {
      "allowedMemberTypes": ["User"],
      "description": "Read-only users can only view data",
      "displayName": "ReadOnly",
      "id": "00000000-0000-0000-0000-000000000003",
      "isEnabled": true,
      "value": "ReadOnly"
    }
  ]
}
EOF
        
        echo -e "${GREEN}✓ Custom app roles manifest created${NC}"
        echo ""
        echo -e "${YELLOW}To apply these roles, you need to update the app registration manifest manually in Azure Portal${NC}"
        echo "or use the Azure CLI with the manifest file."
        echo ""
    fi
}

# Function to show current configuration
show_current_config() {
    local app_id=$1
    
    echo -e "${BLUE}=== Current App Registration Configuration ===${NC}"
    echo ""
    
    # Show app details
    echo "App Registration Details:"
    az ad app show --id "$app_id" --query "{DisplayName:displayName, AppId:appId, SignInAudience:signInAudience}" --output table
    echo ""
    
    # Show service principal details
    echo "Service Principal Details:"
    az ad sp show --id "$app_id" --query "{DisplayName:displayName, AppId:appId, AppRoleAssignmentRequired:appRoleAssignmentRequired}" --output table
    echo ""
    
    # Show API permissions
    echo "API Permissions:"
    az ad app permission list --id "$app_id" --query "[].{Resource:resourceAppId, Permission:resourceAccess[0].id}" --output table
    echo ""
}

# Main execution
echo -e "${BLUE}This script helps you configure access control for your OAuth app registration.${NC}"
echo ""

# List existing app registrations
list_app_registrations

# Get app ID from user
read -p "Enter the App ID (Client ID) of your app registration: " app_id

if [ -z "$app_id" ]; then
    echo -e "${RED}Error: App ID is required${NC}"
    exit 1
fi

# Verify app exists
if ! az ad app show --id "$app_id" &> /dev/null; then
    echo -e "${RED}Error: App registration with ID $app_id not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App registration found${NC}"
echo ""

# Show current configuration
show_current_config "$app_id"

# Configure user assignment
configure_user_assignment "$app_id"

# Configure API permissions
configure_api_permissions "$app_id"

# Create custom app roles
create_custom_app_roles "$app_id"

echo -e "${GREEN}=== Configuration Complete ===${NC}"
echo ""
echo -e "${BLUE}Summary of what was configured:${NC}"
echo "1. User assignment requirements"
echo "2. API permissions"
echo "3. Custom app roles (if requested)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test the OAuth flow with your configured users"
echo "2. Implement role-based access control in your application"
echo "3. Monitor access logs in Azure AD"
echo ""

# Create a summary file
cat > app-registration-summary.txt << EOF
App Registration Access Control Summary
=======================================

App ID: $app_id
Tenant ID: $TENANT_ID
Configured on: $(date)

Configuration Details:
- User assignment: $(az ad sp show --id "$app_id" --query appRoleAssignmentRequired --output tsv)
- API permissions: $(az ad app permission list --id "$app_id" --query length(@))
- Custom roles: See app-roles-manifest.json

For OAuth proxy testing:
1. Use the client ID and secret from your original script
2. Configure your application to check user roles/permissions
3. Implement proper access control based on user assignments

Security Notes:
- Regularly review user assignments
- Monitor access logs
- Rotate client secrets periodically
- Use least privilege principle for permissions
EOF

echo -e "${GREEN}✓ Configuration summary saved to app-registration-summary.txt${NC}"
echo ""
echo -e "${GREEN}Setup completed successfully! 🎉${NC}"
