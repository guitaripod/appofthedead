# Sign in with Apple Setup Guide

## Manual Steps Required

### 1. Apple Developer Portal Setup

1. **Sign in to Apple Developer Portal**
   - Go to https://developer.apple.com/account
   - Sign in with your Apple ID

2. **Configure App ID**
   - Navigate to Certificates, Identifiers & Profiles → Identifiers
   - Select your app identifier or create a new one
   - Enable "Sign In with Apple" capability
   - Click "Configure" next to Sign In with Apple
   - Select "Enable as a primary App ID"
   - Save changes

3. **Create Service ID (for web/worker)**
   - In Identifiers, click the + button
   - Select "Services IDs" and continue
   - Enter a description (e.g., "App of the Dead Web Service")
   - Enter an identifier (e.g., "com.yourcompany.aotd.webservice")
   - Enable "Sign In with Apple"
   - Configure domains and redirect URLs:
     - Domain: `your-worker.your-subdomain.workers.dev`
     - Return URL: `https://your-worker.your-subdomain.workers.dev/auth/callback`
   - Save

4. **Create Private Key**
   - Navigate to Keys section
   - Click the + button to create a new key
   - Enter a key name (e.g., "App of the Dead Sign in with Apple")
   - Enable "Sign In with Apple"
   - Configure the key with your App ID
   - Download the private key (.p8 file) - **SAVE THIS SECURELY**
   - Note the Key ID shown after creation

5. **Note Your Team ID**
   - Found in the top right of the developer portal
   - Or in Membership section

### 2. Xcode Project Setup

1. **Add Capability**
   - Open your project in Xcode
   - Select your target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Sign In with Apple"

2. **Configure Entitlements**
   - The entitlements file has been created at `aotd/aotd.entitlements`
   - Ensure it's added to your target's build settings
   - In Build Settings, search for "Code Signing Entitlements"
   - Set the path to `aotd/aotd.entitlements`

### 3. Cloudflare Worker Setup

1. **Create Cloudflare Account**
   - Sign up at https://cloudflare.com if you don't have an account
   - Add a domain or use workers.dev subdomain

2. **Install Wrangler CLI**
   ```bash
   cd worker
   npm install
   ```

3. **Create D1 Database**
   ```bash
   npx wrangler d1 create aotd-database
   ```
   - Copy the database_id from the output
   - Update `worker/wrangler.toml` with your database_id

4. **Initialize Database Schema**
   ```bash
   npx wrangler d1 execute aotd-database --file=./schema.sql
   ```

5. **Configure Worker Secrets**
   ```bash
   # Set your Apple private key (contents of .p8 file)
   npx wrangler secret put APPLE_PRIVATE_KEY
   ```

6. **Update wrangler.toml**
   - Replace placeholders in `worker/wrangler.toml`:
     - `YOUR_DATABASE_ID`: From step 3
     - `YOUR_APPLE_TEAM_ID`: From Apple Developer Portal
     - `YOUR_APPLE_CLIENT_ID`: Your Service ID identifier
     - `YOUR_APPLE_KEY_ID`: From the key creation step

7. **Deploy Worker**
   ```bash
   npx wrangler deploy
   ```
   - Note your worker URL (e.g., `https://aotd-worker.your-subdomain.workers.dev`)

### 4. iOS App Configuration

1. **Update SyncManager.swift**
   - Replace `baseURL` with your worker URL:
   ```swift
   private let baseURL = "https://aotd-worker.your-subdomain.workers.dev"
   ```

2. **Test Sign in with Apple**
   - Run the app on a real device (Sign in with Apple doesn't work in simulator)
   - Tap the profile button
   - Select "Sign in with Apple"
   - Complete the authentication flow

### 5. Testing the Integration

1. **Verify Authentication**
   - Sign in with Apple in the app
   - Check UserDefaults for stored Apple ID
   - Check that the profile button shows the signed-in state

2. **Test Sync**
   - Make some progress in the app
   - Force a sync by backgrounding and foregrounding the app
   - Check Cloudflare dashboard logs for sync requests

3. **Verify Database**
   ```bash
   # Query your D1 database
   npx wrangler d1 execute aotd-database --command="SELECT * FROM users"
   ```

### Troubleshooting

- **"Invalid client" error**: Check that your Service ID matches in both Apple Developer Portal and wrangler.toml
- **Token validation fails**: Ensure your private key is correctly set as a secret in Cloudflare
- **Sync not working**: Check worker logs in Cloudflare dashboard
- **Sign in button not working**: Ensure you're testing on a real device, not simulator

### Security Notes

- Never commit your Apple private key (.p8 file) to version control
- Keep your Team ID, Client ID, and Key ID in environment variables or secrets
- Use HTTPS for all communication between app and worker
- Implement rate limiting on your worker endpoints