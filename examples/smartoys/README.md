# Smartoys Mautic Deployment

This deployment uses custom Mautic images built from the [Smartoys/mautic-stack](https://github.com/Smartoys/mautic-stack) repository and hosted on GitHub Container Registry (GHCR).

## 🔐 GHCR Authentication

The images are **private** and require authentication before pulling.

### Prerequisites

1. **GitHub Personal Access Token** with `read:packages` scope

### Creating a GitHub Personal Access Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
2. Click **"Generate new token (classic)"**
3. Give it a descriptive name (e.g., "GHCR Pull - Smartoys Mautic")
4. Select the following scope:
   - ✅ `read:packages` - Download packages from GitHub Package Registry
5. Set expiration period (recommended: 90 days)
6. Click **"Generate token"** and save it securely

### Authentication Steps

**Before deploying**, authenticate with GHCR:

```bash
# Set your credentials
export GITHUB_USERNAME="your-github-username"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

You should see: `Login Succeeded`

## 🚀 Deployment

### 1. Database Setup

The database runs in a separate stack. Start it first:

```bash
cd percona
docker compose -f docker-compose.percona.yml up -d
cd ..
```

### 2. Configure Environment Variables

Ensure your environment variables are set in the appropriate `.env` files in the smartoys directory.

### 3. Start Mautic Services

```bash
cd mautic
docker compose up -d
```

### 4. Verify Deployment

```bash
# Check running containers
docker compose ps

# Check logs
docker compose logs -f mautic_web
```

## 📦 Image Details

- **Repository**: https://github.com/Smartoys/mautic-stack
- **Registry**: ghcr.io/smartoys/mautic-stack
- **Current Version**: 6.0.7-apache
- **Services using this image**:
  - `mautic_web` - Web interface
  - `mautic_cron` - Cron jobs
  - `mautic_worker` - Message queue workers

## 🔄 Updating Images

To update to a newer version:

1. **Check available tags**: Visit https://github.com/Smartoys/mautic-stack/pkgs/container/mautic-stack
2. **Update docker-compose.yml**: Change the image tag for all three services
3. **Pull and restart**:
   ```bash
   docker compose pull
   docker compose up -d
   ```

## 🛠️ Troubleshooting

### Error: "unauthorized: authentication required"

**Cause**: Not authenticated with GHCR  
**Solution**: Run the authentication command:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

### Error: "pull access denied"

**Cause**: Token doesn't have `read:packages` scope or user lacks repository access  
**Solution**: 
- Verify token has `read:packages` scope
- Ensure your GitHub account has access to the Smartoys/mautic-stack repository
- Generate a new token if needed

### Error: "manifest unknown"

**Cause**: Image tag doesn't exist in registry  
**Solution**: Check available tags at https://github.com/Smartoys/mautic-stack/pkgs/container/mautic-stack

## 🔒 Security Best Practices

- ✅ Store tokens securely (use environment variables or secrets manager)
- ✅ Rotate tokens regularly (every 90 days recommended)
- ✅ Use tokens with minimal required permissions (`read:packages` only)
- ✅ Never commit tokens to version control
- ✅ Consider using organization-level deploy tokens for production

## 📁 Architecture

```
smartoys/
├── mautic/
│   └── docker-compose.yml    # Mautic services (web, cron, worker)
├── percona/
│   └── docker-compose.percona.yml    # Database service
└── README.md                  # This file
```

## 🌐 Access

The Mautic instance is accessible at: https://newsletter.smartoys.be

## 📝 Notes

- The database (`percona-db`) runs in a separate stack and must be started first
- All three Mautic services share the same volumes for data persistence
- RabbitMQ is used for message queue processing
- Traefik handles SSL/TLS termination with Let's Encrypt (Cloudflare resolver)
