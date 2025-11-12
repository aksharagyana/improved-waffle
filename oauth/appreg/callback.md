# OAuth Callback URL Explained

## 🔄 **Why Callback URL is Required**

The callback URL is **essential** for the OAuth flow to work. Here's why:

### **OAuth Flow Steps:**
1. **User visits** your OAuth proxy (e.g., `http://localhost:4180`)
2. **OAuth proxy redirects** user to Azure AD login page
3. **User authenticates** with Azure AD
4. **Azure AD redirects back** to the callback URL with authorization code
5. **OAuth proxy exchanges** the code for access token
6. **User is redirected** to the protected resource

### **Without Callback URL:**
- ❌ Azure AD doesn't know where to send the user after authentication
- ❌ OAuth flow breaks at step 4
- ❌ No way to complete the authentication process

## 🐳 **Docker Container Callback Issues**

### **Problem 1: Network Accessibility**
```
Azure AD → Callback URL → OAuth Proxy Container
```

**Issues:**
- Azure AD needs to reach the callback URL from the internet
- Docker container might not be accessible from outside
- Localhost URLs won't work for Azure AD

### **Problem 2: Port Mapping**
```
Docker Container (4180) → Host Machine (4180) → Internet
```

**Issues:**
- Port must be properly mapped
- Firewall rules might block access
- Network configuration affects accessibility

## 🔧 **Solutions for Docker OAuth Proxy**

### **Solution 1: Use Public IP/Domain**
```bash
# Instead of localhost, use your public IP or domain
CALLBACK_URL="https://your-public-domain.com/oauth2/callback"
# or
CALLBACK_URL="https://your-public-ip:4180/oauth2/callback"
```

### **Solution 2: Use ngrok for Testing**
```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Expose your local OAuth proxy
ngrok http 4180

# Use the ngrok URL as callback
CALLBACK_URL="https://abc123.ngrok.io/oauth2/callback"
```

### **Solution 3: Use Cloud Tunnel**
```bash
# Use cloudflare tunnel, localtunnel, or similar
npx localtunnel --port 4180

# Use the tunnel URL as callback
CALLBACK_URL="https://xyz.localtunnel.me/oauth2/callback"
```

## 🚨 **Common Docker OAuth Issues**

### **Issue 1: Callback URL Not Reachable**
```
Error: redirect_uri_mismatch
```
**Solution:** Ensure callback URL is accessible from internet

### **Issue 2: Port Not Mapped**
```
Error: Connection refused
```
**Solution:** Properly map Docker port to host

### **Issue 3: Firewall Blocking**
```
Error: Timeout connecting to callback URL
```
**Solution:** Configure firewall rules

## 🎯 **For Your Use Case**

Since you're protecting `aap.tensor.openai.prod` and running OAuth proxy locally:

### **Option 1: Use ngrok (Recommended for Testing)**
```bash
# Install ngrok
brew install ngrok

# Start OAuth proxy
docker run -d --name oauth-proxy -p 4180:4180 \
  --env-file oauth-proxy-config.env \
  quay.io/oauth2-proxy/oauth2-proxy:latest

# Expose with ngrok
ngrok http 4180

# Update app registration with ngrok URL
# https://abc123.ngrok.io/oauth2/callback
```

### **Option 2: Use Public Domain**
```bash
# If you have a public domain
CALLBACK_URL="https://your-domain.com/oauth2/callback"

# Ensure port 4180 is accessible
# Configure DNS and firewall rules
```

### **Option 3: Use Cloud Instance**
```bash
# Deploy OAuth proxy to cloud (Azure, AWS, etc.)
# Use cloud instance public IP/domain
CALLBACK_URL="https://your-cloud-instance.com/oauth2/callback"
```

## 🔍 **Testing Callback URL Accessibility**

### **Test 1: Check if URL is reachable**
```bash
# Test from your machine
curl -I https://your-callback-url.com/oauth2/callback

# Test from external service
# Use online tools like https://www.whatsmydns.net/
```

### **Test 2: Check OAuth proxy logs**
```bash
# View OAuth proxy logs
docker logs oauth-proxy

# Look for callback-related errors
```

### **Test 3: Test OAuth flow**
```bash
# Visit OAuth proxy
curl -v http://localhost:4180

# Check if redirect to Azure AD works
# Check if callback is reached after authentication
```

## 🛠️ **Docker OAuth Proxy Configuration**

### **Environment Variables for Docker:**
```bash
# OAuth proxy configuration
OAUTH2_PROXY_CLIENT_ID=your-client-id
OAUTH2_PROXY_CLIENT_SECRET=your-client-secret
OAUTH2_PROXY_OIDC_ISSUER_URL=https://login.microsoftonline.com/your-tenant-id/v2.0
OAUTH2_PROXY_REDIRECT_URL=https://your-callback-url.com/oauth2/callback
OAUTH2_PROXY_UPSTREAM=https://aap.tensor.openai.prod
OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180
OAUTH2_PROXY_COOKIE_SECRET=your-cookie-secret
```

### **Docker Run Command:**
```bash
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
  --cookie-secret="$OAUTH2_PROXY_COOKIE_SECRET"
```

## 🔒 **Security Considerations**

### **Callback URL Security:**
- ✅ Use HTTPS for callback URLs
- ✅ Validate callback URL in your application
- ✅ Use specific, non-wildcard callback URLs
- ❌ Don't use localhost for production

### **Docker Security:**
- ✅ Use specific port mappings
- ✅ Configure firewall rules
- ✅ Use environment variables for secrets
- ❌ Don't expose unnecessary ports

## 📋 **Quick Setup for Testing**

### **Step 1: Install ngrok**
```bash
brew install ngrok
```

### **Step 2: Start OAuth proxy**
```bash
./run-oauth-proxy.sh
```

### **Step 3: Expose with ngrok**
```bash
ngrok http 4180
```

### **Step 4: Update app registration**
```bash
# Use the ngrok URL as callback
# https://abc123.ngrok.io/oauth2/callback
```

### **Step 5: Test OAuth flow**
```bash
# Visit ngrok URL
curl https://abc123.ngrok.io
```

The callback URL is the "return address" that Azure AD uses to send the user back after authentication. Without it, the OAuth flow cannot complete, and your OAuth proxy won't work!
