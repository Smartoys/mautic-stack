# GitHub Workflow Changes Summary

## Overview
Updated GitHub workflows to automatically build and publish Mautic v6 Docker containers to your private GitHub Container Registry (GHCR) when changes are pushed to the v6 branch.

## Files Modified

### 1. [`.github/workflows/build_publish.yml`](.github/workflows/build_publish.yml)

#### Changes Made:

**Triggers:**
- ✅ Added automatic trigger on pushes to `v6` branch
- ✅ Kept manual `workflow_dispatch` for flexibility
- ✅ Made `mautic_version` input optional with default value `6.0.7`

**Docker Hub Integration:**
- ✅ Removed `DOCKERHUB_USERNAME` environment variable
- ✅ Removed Docker Hub login step (lines 182-186 deleted)
- ✅ Removed `mautic/mautic` from image list in metadata action

**Version Handling:**
- ✅ Added "Determine Mautic version" step to both `test-build` and `build-and-push-image` jobs
- ✅ Uses `${{ env.MAUTIC_VERSION }}` instead of `${{ inputs.mautic_version }}` throughout
- ✅ Defaults to `6.0.7` for automatic builds, allows custom version for manual runs

**Publishing:**
- ✅ Now publishes **only** to `ghcr.io/your-username/repo`
- ✅ Maintains all security features (SAST, SCA, SBOM)
- ✅ Continues multi-arch builds (amd64, arm64)

### 2. [`.github/workflows/pr_test.yml`](.github/workflows/pr_test.yml)

#### Changes Made:

**Triggers:**
- ✅ Added `v6` to branches that trigger PR tests
- ✅ PRs targeting either `main` or `v6` will now run tests

## How It Works Now

### Automatic Builds (Push to v6 branch)

When you push commits to the `v6` branch:

```bash
git checkout v6
git commit -m "Update something"
git push origin v6
```

The workflow will:
1. Automatically trigger
2. Use default Mautic version `6.0.7`
3. Build both `apache` and `fpm` variants
4. Run security scans (Trivy SAST, SCA)
5. Generate SBOM
6. Build multi-arch images (amd64 + arm64)
7. Publish to `ghcr.io/your-username/mautic-stack` with tags:
   - `6.0.7-apache`
   - `6.0.7-fpm`
   - `6.0.7-20260103-apache` (with build date)
   - `6.0.7-20260103-fpm` (with build date)

### Manual Builds (Workflow Dispatch)

To build a specific Mautic version manually:

1. Go to GitHub Actions → "Build and publish a Docker image"
2. Click "Run workflow"
3. Select branch: `v6`
4. Enter custom Mautic version (e.g., `6.0.8`)
5. Optionally enable:
   - Overwrite latest major tag (e.g., `6`)
   - Overwrite latest minor tag (e.g., `6.0`)
   - Tag as latest
6. Run workflow

### Pull Request Tests

When creating a PR to `v6` branch:

```bash
git checkout -b feature/my-change
git push origin feature/my-change
# Create PR targeting v6 branch
```

The PR tests will:
1. Build test images (apache and fpm)
2. Run Trivy SAST scan
3. Run Trivy SCA scan
4. Report results in PR checks

## Image Tags Generated

### Default Automatic Build (Mautic 6.0.7)
- `ghcr.io/your-username/mautic-stack:6.0.7-apache`
- `ghcr.io/your-username/mautic-stack:6.0.7-fpm`
- `ghcr.io/your-username/mautic-stack:6.0.7-20260103-apache`
- `ghcr.io/your-username/mautic-stack:6.0.7-20260103-fpm`

### Manual Build with All Options Enabled
- `ghcr.io/your-username/mautic-stack:6.0.8-apache`
- `ghcr.io/your-username/mautic-stack:6.0.8-fpm`
- `ghcr.io/your-username/mautic-stack:6.0.8-20260103-apache`
- `ghcr.io/your-username/mautic-stack:6.0.8-20260103-fpm`
- `ghcr.io/your-username/mautic-stack:6.0-apache` (if overwrite_latest_minor)
- `ghcr.io/your-username/mautic-stack:6.0-fpm` (if overwrite_latest_minor)
- `ghcr.io/your-username/mautic-stack:6-apache` (if overwrite_latest_major)
- `ghcr.io/your-username/mautic-stack:6-fpm` (if overwrite_latest_major)
- `ghcr.io/your-username/mautic-stack:latest` (if tag_as_latest, apache only)

## Security Features Maintained

✅ **SAST (Static Application Security Testing)**
- Trivy scans for vulnerabilities
- Results uploaded to GitHub Security tab
- Won't fail builds on vulnerabilities found

✅ **SCA (Software Composition Analysis)**  
- Scans for vulnerable dependencies
- Comprehensive vulnerability reporting

✅ **SBOM (Software Bill of Materials)**
- Generated and attached to images
- Supports supply chain security

✅ **Build Provenance**
- Metadata about how images were built
- Improves transparency and trust

## GitHub Permissions

The workflow uses the default `GITHUB_TOKEN` which has the necessary permissions:

**For publishing to GHCR:**
```yaml
permissions:
  contents: read
  packages: write
```

**For security scanning:**
```yaml
permissions:
  contents: read
  security-events: write
```

No additional secrets are required beyond the default `GITHUB_TOKEN`.

## Package Visibility

By default, GHCR packages are **private**. To change visibility:

1. Go to your repository on GitHub
2. Click "Packages" in the right sidebar
3. Click on the package name
4. Go to "Package settings"
5. Change visibility as needed

## Testing the Setup

### 1. Test Automatic Build
```bash
# From v6 branch
git commit --allow-empty -m "Test workflow trigger"
git push origin v6
```

Then check:
- Actions tab → verify workflow is running
- All jobs complete successfully
- Images appear in Packages

### 2. Test Manual Build
1. Actions → "Build and publish a Docker image"
2. Run workflow with custom version
3. Verify custom version is used in tags

### 3. Test PR Workflow
```bash
# Create test branch
git checkout -b test-pr-workflow
git commit --allow-empty -m "Test PR checks"
git push origin test-pr-workflow
```
Create PR targeting `v6` branch → verify checks run

### 4. Pull and Test Image
```bash
# Login to GHCR (if package is private)
echo $GITHUB_TOKEN | docker login ghcr.io -u your-username --password-stdin

# Pull image
docker pull ghcr.io/your-username/mautic-stack:6.0.7-apache

# Test image
docker run --rm ghcr.io/your-username/mautic-stack:6.0.7-apache php --version
# Should output: PHP 8.3.x
```

## Updating Default Mautic Version

When a new Mautic 6.x version is released, update in two places in [`.github/workflows/build_publish.yml`](.github/workflows/build_publish.yml):

**Line 12 (workflow_dispatch input default):**
```yaml
default: '6.0.8'  # Update this
```

**Lines 41-45 and 161-165 (version determination steps):**
```yaml
else
  # For automatic builds, use default version
  VERSION="6.0.8"  # Update this
fi
```

## Workflow Architecture

```
Push to v6 → Determine Version (6.0.7) → Build Test Images (apache, fpm)
                                       ↓
                                    Security Scans (SAST, SCA, SBOM)
                                       ↓
                                    Build Multi-arch Images
                                       ↓
                                    Login to GHCR
                                       ↓
                                    Push Images with Tags
```

## What Was Removed

- ❌ Docker Hub username environment variable
- ❌ Docker Hub login step
- ❌ Docker Hub image reference in metadata
- ❌ `DOCKERHUB_TOKEN` secret requirement
- ❌ Publishing to `mautic/mautic` Docker Hub repository

## What Was Kept

- ✅ All security scanning (SAST, SCA, SBOM)
- ✅ Multi-architecture builds (amd64, arm64)
- ✅ Build artifacts and caching
- ✅ Flexible tagging strategy
- ✅ Manual workflow dispatch option
- ✅ Support for multiple Mautic major versions (5, 6, 7)

## Troubleshooting

### Workflow doesn't trigger on push
- Ensure you're pushing to the `v6` branch specifically
- Check Actions tab for any disabled workflows
- Verify repository settings allow Actions to run

### Images not appearing in Packages
- Check workflow completed successfully
- Verify GITHUB_TOKEN has `packages: write` permission
- Check repository Settings → Actions → General → Workflow permissions

### Permission denied when pulling images
- Ensure package visibility is set correctly
- Login to GHCR with appropriate credentials
- For private packages, use personal access token with `read:packages` scope

### Build fails with version error
- Ensure Mautic version is valid (exists in mautic/recommended-project)
- Check version format is correct (e.g., `6.0.7` not `v6.0.7`)
- Verify version matches supported major version (5, 6, or 7)

## Next Steps

1. ✅ Workflows are updated and ready to use
2. Push to v6 branch to trigger first automatic build
3. Monitor Actions tab to ensure build completes
4. Verify images in Packages section
5. Update default Mautic version when new releases are available
6. Configure package visibility as needed

## Reference Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Metadata Action](https://github.com/docker/metadata-action)
- [Trivy Scanning](https://github.com/aquasecurity/trivy-action)
- [Mautic Documentation](https://docs.mautic.org/)
