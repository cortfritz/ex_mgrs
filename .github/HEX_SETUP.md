# Hex.pm Publishing Setup

This guide explains how to set up the GitHub Action to automatically publish to Hex.pm when pushing to the `hex` branch.

## 1. Generate a Hex API Key

First, you need to generate an API key from Hex.pm:

```bash
# Authenticate with Hex (if not already authenticated)
mix hex.user auth

# Generate a new API key for CI/CD
mix hex.user key generate --permissions "api:write"
```

This will output an API key. **Copy this key immediately** - you won't be able to see it again!

The key will look something like: `abc123def456...` (a long hexadecimal string)

## 2. Add the API Key to GitHub Secrets

1. Go to your GitHub repository: https://github.com/cortfritz/ex_mgrs
2. Click on **Settings** (top menu)
3. In the left sidebar, click on **Secrets and variables** → **Actions**
4. Click the **New repository secret** button
5. Enter the following:
   - **Name**: `HEX_API_KEY`
   - **Secret**: Paste the API key you generated in step 1
6. Click **Add secret**

## 3. How to Publish

Once the secret is configured, publishing is simple:

```bash
# Make your changes and commit them
git add .
git commit -m "Prepare version 0.0.6"

# Push to the hex branch to trigger publishing
git push origin main:hex

# Or if you're on the hex branch:
git checkout hex
git merge main
git push origin hex
```

The GitHub Action will automatically:
1. Set up the Elixir environment
2. Install dependencies
3. Run tests
4. Publish to Hex.pm (if tests pass)

## 4. Verify Publication

After the action completes, verify your package at:
https://hex.pm/packages/ex_mgrs

## Notes

- The API key has `api:write` permissions, which allows publishing packages
- Keep your API key secret and never commit it to the repository
- If you need to revoke the key, run: `mix hex.user key revoke <key_name>`
- You can list all your keys with: `mix hex.user key list`
