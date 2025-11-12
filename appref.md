
🔹 Step 1: Create or Open the App Registration

Go to Azure Portal

Navigate to Azure Active Directory → App registrations.

Either:

Click New registration to create a new one, OR

Open the existing app registration if it already exists.


tep 2: Add Redirect URIs (Callback URLs)

Inside the app registration, go to Authentication (left-hand menu).

Under Redirect URIs, click Add a platform → choose Web (for web apps) or Single-page application (SPA) if applicable.

Add all three callback URLs your client gave you, for example:

https://clientapp.com/auth/callback

https://staging.clientapp.com/auth/callback

https://localhost:3000/auth/callback (for dev/testing)

Save the changes.


Step 3: Configure Logout URL (optional)

If the client gave you a Post logout redirect URI, add it under Logout URL in the same Authentication blade.


Step 4: Enable Required Settings

Implicit grant / Hybrid flows (if needed by the client’s app): under Authentication → enable ID tokens and/or Access tokens.

Certificates & secrets → Create a new Client secret (copy the value immediately, as it won’t be visible later).

API permissions → Grant permissions requested by the client’s app (usually Microsoft Graph → User.Read at a minimum).



Step 5: Share Credentials with Client

Give the client:

Application (client) ID

Directory (tenant) ID

Client secret (if generated)

The configured redirect URIs

They will use these in their OAuth2 / OpenID Connect setup.
