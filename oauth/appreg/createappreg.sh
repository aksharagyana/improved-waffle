#!/bin/bash

# Azure App Registration Creation Script for OAuth Proxy
# This script creates an app registration with callback URL for aap.tensor.openai.prod

set -e

# Configuration
APP_NAME="oauth-proxy-tensor-openai"
CALLBACK_URL="https://aap.tensor.openai.prod/oauth2/callback"
TENANT_ID=""
SUBSCRIPTION_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure App Registration Creation for OAuth Proxy ===${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}You are not logged in to Azure CLI. Please log in first.${NC}"
    az login
fi

# Get current subscription info
echo -e "${BLUE}Getting current Azure subscription information...${NC}"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
echo ""

# Create the app registration
echo -e "${BLUE}Creating app registration: $APP_NAME${NC}"
APP_ID=$(az ad app create \
    --display-name "$APP_NAME" \
    --web-redirect-uris "$CALLBACK_URL" \
    --query appId \
    --output tsv)

if [ -z "$APP_ID" ]; then
    echo -e "${RED}Error: Failed to create app registration${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App registration created successfully${NC}"
echo "App ID (Client ID): $APP_ID"
echo ""

# Create a service principal
echo -e "${BLUE}Creating service principal...${NC}"
SP_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)
echo -e "${GREEN}✓ Service principal created${NC}"
echo ""

# Generate client secret
echo -e "${BLUE}Generating client secret...${NC}"
CLIENT_SECRET=$(az ad app credential reset \
    --id "$APP_ID" \
    --query password \
    --output tsv)

if [ -z "$CLIENT_SECRET" ]; then
    echo -e "${RED}Error: Failed to generate client secret${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Client secret generated successfully${NC}"
echo ""

# Display the credentials
echo -e "${GREEN}=== OAuth Proxy Configuration ===${NC}"
echo ""
echo -e "${YELLOW}Save these credentials securely:${NC}"
echo "----------------------------------------"
echo "Client ID:     $APP_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Tenant ID:     $TENANT_ID"
echo "Callback URL:  $CALLBACK_URL"
echo "----------------------------------------"
echo ""

# Create a configuration file for OAuth proxy
echo -e "${BLUE}Creating OAuth proxy configuration file...${NC}"
cat > oauth-proxy-config.env << EOF
# OAuth Proxy Configuration
# Generated on $(date)

# Azure App Registration Details
OAUTH2_PROXY_CLIENT_ID=$APP_ID
OAUTH2_PROXY_CLIENT_SECRET=$CLIENT_SECRET
OAUTH2_PROXY_OIDC_ISSUER_URL=https://login.microsoftonline.com/$TENANT_ID/v2.0
OAUTH2_PROXY_SKIP_PROVIDER_BUTTON=true
OAUTH2_PROXY_EMAIL_DOMAINS=*
OAUTH2_PROXY_UPSTREAM=https://aap.tensor.openai.prod
OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180
OAUTH2_PROXY_REDIRECT_URL=$CALLBACK_URL
OAUTH2_PROXY_COOKIE_SECRET=$(openssl rand -base64 32)
EOF

echo -e "${GREEN}✓ Configuration file created: oauth-proxy-config.env${NC}"
echo ""

# Create Docker run command
echo -e "${BLUE}Creating Docker run command...${NC}"
cat > run-oauth-proxy.sh << 'EOF'
#!/bin/bash

# Load environment variables
source oauth-proxy-config.env

# Run OAuth proxy container
docker run -d \
    --name oauth-proxy \
    --env-file oauth-proxy-config.env \
    -p 4180:4180 \
    quay.io/oauth2-proxy/oauth2-proxy:latest \
    --provider=oidc \
    --oidc-issuer-url="$OAUTH2_PROXY_OIDC_ISSUER_URL" \
    --client-id="$OAUTH2_PROXY_CLIENT_ID" \
    --client-secret="$OAUTH2_PROXY_CLIENT_SECRET" \
    --redirect-url="$OAUTH2_PROXY_REDIRECT_URL" \
    --upstream="$OAUTH2_PROXY_UPSTREAM" \
    --http-address="$OAUTH2_PROXY_HTTP_ADDRESS" \
    --email-domains="$OAUTH2_PROXY_EMAIL_DOMAINS" \
    --skip-provider-button="$OAUTH2_PROXY_SKIP_PROVIDER_BUTTON" \
    --cookie-secret="$OAUTH2_PROXY_COOKIE_SECRET"
EOF

chmod +x run-oauth-proxy.sh
echo -e "${GREEN}✓ Docker run script created: run-oauth-proxy.sh${NC}"
echo ""

# Display next steps
echo -e "${GREEN}=== Next Steps ===${NC}"
echo ""
echo "1. Test the OAuth proxy locally:"
echo "   ./run-oauth-proxy.sh"
echo ""
echo "2. Access your protected service through OAuth proxy:"
echo "   http://localhost:4180"
echo ""
echo "3. The OAuth proxy will redirect to Azure AD for authentication"
echo "   and then forward requests to aap.tensor.openai.prod"
echo ""
echo "4. To stop the OAuth proxy:"
echo "   docker stop oauth-proxy && docker rm oauth-proxy"
echo ""

# Security reminder
echo -e "${YELLOW}=== Security Reminder ===${NC}"
echo ""
echo "⚠️  IMPORTANT: Keep your client secret secure!"
echo "   - Never commit the client secret to version control"
echo "   - Store it securely (e.g., Azure Key Vault, environment variables)"
echo "   - Rotate the secret regularly"
echo ""

echo -e "${GREEN}Setup completed successfully! 🎉${NC}"
