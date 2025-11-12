#!/bin/bash

# Enhanced Azure App Registration Group Access Configuration Script
# This script specifically handles both individual users AND Entra ID/AD groups

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure App Registration Group Access Configuration ===${NC}"
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

# Function to list available groups
list_groups() {
    echo -e "${BLUE}Available Security Groups:${NC}"
    az ad group list --query "[].{DisplayName:displayName, ObjectId:id, Description:description}" --output table --max-items 20
    echo ""
}

# Function to list available users
list_users() {
    echo -e "${BLUE}Available Users:${NC}"
    az ad user list --query "[].{DisplayName:displayName, UserPrincipalName:userPrincipalName, ObjectId:id}" --output table --max-items 20
    echo ""
}

# Function to assign group to app registration
assign_group_to_app() {
    local app_id=$1
    local group_id=$2
    local group_name=$3
    
    echo -e "${BLUE}Assigning group '$group_name' to app registration...${NC}"
    
    # Get the service principal ID
    sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
    
    if [ -z "$sp_id" ]; then
        echo -e "${RED}Error: Could not find service principal for app ID $app_id${NC}"
        return 1
    fi
    
    # Assign group to the app using Microsoft Graph API
    az rest --method POST \
        --uri "https://graph.microsoft.com/v1.0/groups/$group_id/appRoleAssignments" \
        --body "{\"principalId\":\"$group_id\",\"resourceId\":\"$sp_id\",\"appRoleId\":\"00000000-0000-0000-0000-000000000000\"}" \
        --headers "Content-Type=application/json" \
        --output none
    
    echo -e "${GREEN}✓ Group '$group_name' assigned successfully${NC}"
}

# Function to assign user to app registration
assign_user_to_app() {
    local app_id=$1
    local user_id=$2
    local user_name=$3
    
    echo -e "${BLUE}Assigning user '$user_name' to app registration...${NC}"
    
    # Get the service principal ID
    sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
    
    if [ -z "$sp_id" ]; then
        echo -e "${RED}Error: Could not find service principal for app ID $app_id${NC}"
        return 1
    fi
    
    # Assign user to the app using Microsoft Graph API
    az rest --method POST \
        --uri "https://graph.microsoft.com/v1.0/users/$user_id/appRoleAssignments" \
        --body "{\"principalId\":\"$user_id\",\"resourceId\":\"$sp_id\",\"appRoleId\":\"00000000-0000-0000-0000-000000000000\"}" \
        --headers "Content-Type=application/json" \
        --output none
    
    echo -e "${GREEN}✓ User '$user_name' assigned successfully${NC}"
}

# Function to configure assignment requirements
configure_assignment_requirements() {
    local app_id=$1
    
    echo -e "${BLUE}=== Assignment Requirements Configuration ===${NC}"
    echo ""
    echo "Choose assignment mode:"
    echo "1. ${YELLOW}Assignment Required${NC} - Only assigned users/groups can access"
    echo "2. ${YELLOW}Assignment Optional${NC} - All users in tenant can access (default)"
    echo ""
    
    read -p "Do you want to require assignment? (y/n): " require_assignment
    
    if [[ $require_assignment =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Setting assignment required...${NC}"
        az ad sp update --id "$app_id" --set appRoleAssignmentRequired=true
        echo -e "${GREEN}✓ Assignment required enabled${NC}"
        return 0
    else
        echo -e "${BLUE}Setting assignment optional...${NC}"
        az ad sp update --id "$app_id" --set appRoleAssignmentRequired=false
        echo -e "${GREEN}✓ Assignment optional enabled (all users can access)${NC}"
        return 1
    fi
}

# Function to manage group assignments
manage_group_assignments() {
    local app_id=$1
    
    echo -e "${BLUE}=== Group Assignment Management ===${NC}"
    echo ""
    
    while true; do
        echo "Group Assignment Options:"
        echo "1. List available groups"
        echo "2. Assign a group to the app"
        echo "3. List currently assigned groups"
        echo "4. Remove a group assignment"
        echo "5. Done with group assignments"
        echo ""
        
        read -p "Choose an option (1-5): " group_option
        
        case $group_option in
            1)
                list_groups
                ;;
            2)
                list_groups
                read -p "Enter the Object ID of the group to assign: " group_id
                
                if [ ! -z "$group_id" ]; then
                    # Get group name for display
                    group_name=$(az ad group show --group "$group_id" --query displayName --output tsv)
                    assign_group_to_app "$app_id" "$group_id" "$group_name"
                fi
                ;;
            3)
                echo -e "${BLUE}Currently assigned groups:${NC}"
                sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
                az rest --method GET \
                    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                    --query "value[?principalType=='Group'].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" \
                    --output table
                echo ""
                ;;
            4)
                echo -e "${BLUE}Currently assigned groups:${NC}"
                sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
                az rest --method GET \
                    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                    --query "value[?principalType=='Group'].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" \
                    --output table
                echo ""
                
                read -p "Enter the Object ID of the group to remove: " group_id
                if [ ! -z "$group_id" ]; then
                    # Find the assignment ID
                    assignment_id=$(az rest --method GET \
                        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                        --query "value[?principalId=='$group_id'].id" --output tsv)
                    
                    if [ ! -z "$assignment_id" ]; then
                        az rest --method DELETE \
                            --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo/$assignment_id"
                        echo -e "${GREEN}✓ Group assignment removed${NC}"
                    else
                        echo -e "${RED}Group assignment not found${NC}"
                    fi
                fi
                ;;
            5)
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 1-5.${NC}"
                ;;
        esac
        echo ""
    done
}

# Function to manage user assignments
manage_user_assignments() {
    local app_id=$1
    
    echo -e "${BLUE}=== User Assignment Management ===${NC}"
    echo ""
    
    while true; do
        echo "User Assignment Options:"
        echo "1. List available users"
        echo "2. Assign a user to the app"
        echo "3. List currently assigned users"
        echo "4. Remove a user assignment"
        echo "5. Done with user assignments"
        echo ""
        
        read -p "Choose an option (1-5): " user_option
        
        case $user_option in
            1)
                list_users
                ;;
            2)
                list_users
                read -p "Enter the Object ID of the user to assign: " user_id
                
                if [ ! -z "$user_id" ]; then
                    # Get user name for display
                    user_name=$(az ad user show --id "$user_id" --query displayName --output tsv)
                    assign_user_to_app "$app_id" "$user_id" "$user_name"
                fi
                ;;
            3)
                echo -e "${BLUE}Currently assigned users:${NC}"
                sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
                az rest --method GET \
                    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                    --query "value[?principalType=='User'].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" \
                    --output table
                echo ""
                ;;
            4)
                echo -e "${BLUE}Currently assigned users:${NC}"
                sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
                az rest --method GET \
                    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                    --query "value[?principalType=='User'].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" \
                    --output table
                echo ""
                
                read -p "Enter the Object ID of the user to remove: " user_id
                if [ ! -z "$user_id" ]; then
                    # Find the assignment ID
                    assignment_id=$(az rest --method GET \
                        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
                        --query "value[?principalId=='$user_id'].id" --output tsv)
                    
                    if [ ! -z "$assignment_id" ]; then
                        az rest --method DELETE \
                            --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo/$assignment_id"
                        echo -e "${GREEN}✓ User assignment removed${NC}"
                    else
                        echo -e "${RED}User assignment not found${NC}"
                    fi
                fi
                ;;
            5)
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 1-5.${NC}"
                ;;
        esac
        echo ""
    done
}

# Function to show current assignments
show_current_assignments() {
    local app_id=$1
    
    echo -e "${BLUE}=== Current App Registration Assignments ===${NC}"
    echo ""
    
    # Show app details
    echo "App Registration Details:"
    az ad app show --id "$app_id" --query "{DisplayName:displayName, AppId:appId, SignInAudience:signInAudience}" --output table
    echo ""
    
    # Show service principal details
    echo "Service Principal Details:"
    az ad sp show --id "$app_id" --query "{DisplayName:displayName, AppId:appId, AppRoleAssignmentRequired:appRoleAssignmentRequired}" --output table
    echo ""
    
    # Show current assignments
    sp_id=$(az ad sp show --id "$app_id" --query id --output tsv)
    echo "Current Assignments:"
    az rest --method GET \
        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$sp_id/appRoleAssignedTo" \
        --query "value[].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" \
        --output table
    echo ""
}

# Main execution
echo -e "${BLUE}This script helps you configure group and user access for your OAuth app registration.${NC}"
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
show_current_assignments "$app_id"

# Configure assignment requirements
if configure_assignment_requirements "$app_id"; then
    echo ""
    echo -e "${YELLOW}Since assignment is required, you need to assign users and/or groups.${NC}"
    echo ""
    
    # Manage group assignments
    manage_group_assignments "$app_id"
    
    # Manage user assignments
    manage_user_assignments "$app_id"
fi

echo -e "${GREEN}=== Configuration Complete ===${NC}"
echo ""
echo -e "${BLUE}Summary of what was configured:${NC}"
echo "1. Assignment requirements"
echo "2. Group assignments (if any)"
echo "3. User assignments (if any)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test the OAuth flow with assigned users/groups"
echo "2. Monitor access logs in Azure AD"
echo "3. Regularly review and update assignments"
echo ""

# Create a summary file
cat > group-access-summary.txt << EOF
App Registration Group Access Summary
====================================

App ID: $app_id
Tenant ID: $TENANT_ID
Configured on: $(date)

Assignment Requirements: $(az ad sp show --id "$app_id" --query appRoleAssignmentRequired --output tsv)

Current Assignments:
$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$(az ad sp show --id "$app_id" --query id --output tsv)/appRoleAssignedTo" --query "value[].{DisplayName:principalDisplayName, ObjectId:principalId, Type:principalType}" --output table)

For OAuth proxy testing:
1. Use the client ID and secret from your original script
2. Test with users who are assigned to the app
3. Test with users who are members of assigned groups
4. Verify access is denied for non-assigned users

Security Notes:
- Group assignments are inherited by group members
- Users can be assigned directly or through group membership
- Regularly review group memberships and assignments
- Monitor access logs for unauthorized access attempts
EOF

echo -e "${GREEN}✓ Configuration summary saved to group-access-summary.txt${NC}"
echo ""
echo -e "${GREEN}Setup completed successfully! 🎉${NC}"
