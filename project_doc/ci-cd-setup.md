# CI/CD Setup Documentation

## Overview

This project uses GitHub Actions for continuous integration and deployment. The workflow automatically runs tests on pull requests and publishes to Hex when code is merged to the main branch.

## Workflow Configuration

### Branch Strategy
- **Default branch**: `develop` (for development work)
- **Main branch**: `main` (for releases)
- Workflow triggers on:
  - Push to `main` branch
  - Pull requests to `main` or `develop` branches

### Jobs

#### Test Job
- Runs on all pushes and pull requests
- Sets up Elixir 1.18.2 and OTP 26
- Sets up Rust toolchain for NIF compilation
- Installs dependencies with caching
- Compiles the project
- Runs tests
- Runs dialyzer for static analysis with enhanced warnings

#### Publish Job
- Only runs when code is pushed to `main` branch in the original repository (`cortfritz/ex_mgrs`)
- Requires the test job to pass first
- Automatically bumps the patch version
- Commits and pushes the version bump
- Publishes the package to Hex

## Required Setup

### 1. GitHub Repository Settings

1. Go to your repository settings
2. Set the default branch to `develop`
3. Protect the `main` branch:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Include administrators in these restrictions
4. Ensure the repository has Actions enabled with appropriate permissions

### 2. Hex API Key

#### For Repository Owner (cortfritz)
1. Get your Hex API key from https://hex.pm/account/keys
2. Add it as a GitHub secret:
   - Go to repository Settings → Secrets and variables → Actions
   - Create a new repository secret named `HEX_API_KEY`
   - Paste your Hex API key as the value

#### For Contributors (Fork Owners)
If you want to publish your fork to Hex under your own package name:

1. **Update package configuration in `mix.exs`**:
   ```elixir
   defp package do
     [
       name: "your_package_name",  # Change from "ex_mgrs" to your unique name
       # ... rest of package config
       links: %{"GitHub" => "https://github.com/your-username/your-fork-name"}
     ]
   end
   ```

2. **Update the workflow condition** in `.github/workflows/ci-cd.yml`:
   ```yaml
   if: github.ref == 'refs/heads/main' && github.event_name == 'push' && github.repository == 'your-username/your-fork-name'
   ```

3. **Get your Hex API key** from https://hex.pm/account/keys

4. **Add it as a GitHub secret** in your fork:
   - Go to your fork's Settings → Secrets and variables → Actions
   - Create a new repository secret named `HEX_API_KEY`
   - Paste your Hex API key as the value

**Note**: Make sure your package name is unique on Hex to avoid conflicts with existing packages.

### 3. Repository Permissions

The workflow needs permission to push commits back to the repository for version bumping. This is handled automatically by the `GITHUB_TOKEN` secret.

**Note**: The workflow uses `fetch-depth: 0` and `token: ${{ secrets.GITHUB_TOKEN }}` to ensure it can push commits back to the repository for version bumping.

## Version Bumping

The workflow automatically bumps the patch version (e.g., 0.0.3 → 0.0.4) when publishing. If you need to bump major or minor versions, you'll need to:

1. Manually update the version in `mix.exs`
2. Commit and push to `main`
3. The workflow will then publish with the new version

## Manual Publishing

If you need to publish manually:

```bash
# Bump version (optional)
mix version bump patch  # or major/minor

# Publish to Hex
mix hex.publish
```

## Development Tasks

### Running Dialyzer Locally

```bash
# Run dialyzer analysis
mix dialyzer

# Clean dialyzer PLT files (if you need to rebuild)
mix dialyzer --plt
```

## Troubleshooting

### Common Issues

1. **Hex API Key not found**: Ensure the `HEX_API_KEY` secret is set in repository settings
2. **Permission denied**: Check that the `GITHUB_TOKEN` has write permissions
3. **Version already exists**: The workflow will fail if trying to publish a version that already exists on Hex

### Debugging

- Check the Actions tab in your GitHub repository for detailed logs
- The workflow includes echo statements to show version information
- Failed builds will show exactly which step failed

## Security Notes

- The `HEX_API_KEY` is encrypted and only accessible during workflow runs
- The workflow uses the official Elixir and Rust setup actions
- Dependencies are cached to speed up builds and reduce external requests
- **Fork Protection**: The publish job only runs on the original repository (`cortfritz/ex_mgrs`) to prevent forks from accidentally publishing to your Hex package 