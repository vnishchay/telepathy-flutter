# GitHub Token Setup for Release Creation

## Required Permissions

To use the `create_release.sh` script, your GitHub Personal Access Token needs the following permissions:

### Classic Token (Recommended)

When creating a **Personal Access Token (classic)**, select these scopes:

- ✅ **`repo`** (Full control of private repositories)
  - This includes:
    - `repo:status` - Access commit status
    - `repo_deployment` - Access deployment status
    - `public_repo` - Access public repositories
    - `repo:invite` - Access repository invitations
    - `security_events` - Read and write security events

**Note**: The `repo` scope is sufficient for creating releases and uploading assets.

### Fine-Grained Token (Alternative)

If using a **Fine-Grained Personal Access Token**, grant these permissions:

- **Repository Access**: Select your repository (`vnishchay/telepathy-flutter`)
- **Repository Permissions**:
  - ✅ **Contents**: Read and write (to create releases)
  - ✅ **Metadata**: Read-only (always required)

## Step-by-Step Token Creation

### Method 1: Classic Token (Easiest)

1. **Go to GitHub Settings**:
   - Visit: https://github.com/settings/tokens
   - Or: GitHub → Your Profile → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**:
   - Click **"Generate new token"** → **"Generate new token (classic)"**

3. **Configure Token**:
   - **Note**: `PhoneBuddy Release Script`
   - **Expiration**: Choose your preferred duration (90 days, 1 year, or no expiration)
   - **Select scopes**: Check **`repo`** (this automatically selects all repo-related permissions)

4. **Generate and Copy**:
   - Click **"Generate token"**
   - **IMPORTANT**: Copy the token immediately (you won't see it again!)
   - It will look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

5. **Use the Token**:
   ```bash
   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ./create_release.sh
   ```

### Method 2: Fine-Grained Token

1. **Go to GitHub Settings**:
   - Visit: https://github.com/settings/tokens?type=beta

2. **Generate New Token**:
   - Click **"Generate new token"**

3. **Configure Token**:
   - **Token name**: `PhoneBuddy Release Script`
   - **Expiration**: Choose your preferred duration
   - **Repository access**: Select **"Only select repositories"** → Choose `telepathy-flutter`
   - **Repository permissions**:
     - **Contents**: Read and write
     - **Metadata**: Read (automatically included)

4. **Generate and Use**:
   - Click **"Generate token"**
   - Copy the token and use it the same way as above

## Security Best Practices

### ✅ Do:
- Use tokens with **minimal required permissions** (just `repo` scope)
- Set an **expiration date** (don't use "No expiration" unless necessary)
- **Store tokens securely** (use environment variables, not in scripts)
- **Revoke tokens** when no longer needed

### ❌ Don't:
- Commit tokens to Git (they're in `.gitignore` for a reason!)
- Share tokens publicly
- Use tokens with excessive permissions
- Leave tokens in shell history (use `export` in a separate session)

## Alternative: Using GitHub CLI (No Token Needed)

If you prefer not to use a token, you can use GitHub CLI which handles authentication:

```bash
# Install GitHub CLI (if not installed)
# Ubuntu/Debian: sudo apt install gh
# macOS: brew install gh

# Authenticate (one-time setup)
gh auth login

# Create release
gh release create v1.0.0 \
  --title "PhoneBuddy v1.0.0" \
  --notes "Release notes here" \
  releases/phonebuddy-v1.0.0-release.apk
```

## Troubleshooting

### Error: "Bad credentials"
- Token is invalid or expired
- Solution: Generate a new token

### Error: "Resource not accessible by integration"
- Token doesn't have `repo` scope
- Solution: Create a new token with `repo` permissions

### Error: "Not Found"
- Repository doesn't exist or token doesn't have access
- Solution: Verify repository name and token permissions

### Error: "Validation Failed"
- Release tag already exists
- Solution: Use a different version number or delete the existing tag

## Quick Reference

**Minimum Required Scope**: `repo`

**Token Format**: `ghp_` (classic) or `github_pat_` (fine-grained)

**Environment Variable**: `GITHUB_TOKEN`

**Script Usage**:
```bash
export GITHUB_TOKEN=your_token_here
./create_release.sh
```

