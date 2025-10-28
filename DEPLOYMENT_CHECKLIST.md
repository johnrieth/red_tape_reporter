# Red Tape Reporter - Production Deployment Checklist

## ✅ Completed

- [x] All tests passing (5 tests, 15 assertions)
- [x] Host authorization enabled for redtape.la
- [x] SSL/HTTPS configuration enabled
- [x] Rate limiting configured (rack-attack)
- [x] Email verification system implemented
- [x] Domain configured to redtape.la
- [x] Mailer sending from noreply@verify.redtape.la
- [x] Docker configuration ready
- [x] Security headers configured

## ⚠️ Required Before First Deployment

### 1. Production Credentials (REQUIRED)

Create production credentials with your Resend API key:

```bash
EDITOR=vim rails credentials:edit --environment production
```

Add this content:
```yaml
resend:
  api_key: re_YourResendApiKey_Here
```

This will create:
- `config/credentials/production.yml.enc` (encrypted, safe to commit)
- `config/credentials/production.key` (SECRET - DO NOT COMMIT)

### 2. Update Kamal Deploy Config

Edit `config/deploy.yml` and replace these placeholder values:

**Line 5** - Docker image:
```yaml
# Current: image: your-user/red_tape_reporter
# Change to:
image: ghcr.io/YOUR_GITHUB_USERNAME/red_tape_reporter
# OR
image: YOUR_DOCKERHUB_USERNAME/red_tape_reporter
```

**Line 10** - Server IP:
```yaml
# Current: - 192.168.0.1
# Change to:
    - YOUR_ACTUAL_SERVER_IP
```

**Line 28** - Registry username:
```yaml
# Current: username: your-user
# Change to:
username: YOUR_GITHUB_USERNAME  # or Docker Hub username
```

### 3. Kamal Secrets File

Update `.kamal/secrets` with:

```bash
KAMAL_REGISTRY_PASSWORD=your_github_or_dockerhub_personal_access_token
RAILS_MASTER_KEY=paste_content_of_config_credentials_production_key_here
```

### 4. Resend Email Setup

1. Sign up at https://resend.com
2. Add and verify domain: `redtape.la`
3. Add DNS records they provide (SPF, DKIM, DMARC)
4. Verify sending domain: `verify.redtape.la`
5. Create API key
6. Add API key to production credentials (step 1)

### 5. DNS Configuration

Point your domain to your server:

```
redtape.la    →  A record  →  YOUR_SERVER_IP
```

### 6. Server Requirements

Ensure your server has:

- [ ] Ubuntu/Debian Linux
- [ ] Docker installed (`curl -fsSL https://get.docker.com | sh`)
- [ ] SSH access configured
- [ ] Firewall allows ports 80 and 443
- [ ] At least 1GB RAM, 1 CPU core
- [ ] Root or sudo access for initial setup

## Deployment Commands

### First Time Setup

```bash
# This will set up Docker, SSL certificates, and deploy
kamal setup
```

### Regular Deployments

```bash
# Deploy new version
kamal deploy

# View logs
kamal app logs -f

# Access Rails console
kamal app exec --interactive "bin/rails console"

# Check app status
kamal app details
```

## Post-Deployment Verification

1. **Health check**: `curl https://redtape.la/up`
   - Should return: `200 OK`

2. **Submit test report**: Visit https://redtape.la
   - Fill out form
   - Check verification email arrives at test address
   - Click verification link
   - Confirm report is verified

3. **Check SSL**: Visit https://redtape.la
   - Should show valid SSL certificate (Let's Encrypt)
   - No certificate warnings

4. **Rate limiting test**:
   - Submit 6 reports from same IP quickly
   - 6th should be blocked

## Configuration Summary

- **App Domain**: redtape.la
- **Mail From**: noreply@verify.redtape.la
- **Database**: SQLite with persistent Docker volume
- **Job Queue**: Solid Queue (in-process)
- **Cache**: Solid Cache (SQLite)
- **Web Server**: Puma + Thruster
- **SSL**: Let's Encrypt (auto-managed by Kamal)

## Security Features Enabled

- ✅ Force SSL/HTTPS
- ✅ Secure cookies
- ✅ Host authorization (redtape.la + subdomains)
- ✅ Rate limiting (5 reports/IP/hour, 3 reports/email/day)
- ✅ Email verification required
- ✅ Non-root Docker user
- ✅ HSTS headers
- ✅ Credentials encryption

## Important Files

**DO COMMIT**:
- `config/credentials/production.yml.enc` (encrypted)
- `config/deploy.yml` (after updating placeholders)
- `Dockerfile`
- `.dockerignore`

**DO NOT COMMIT**:
- `config/credentials/production.key` (add to `.gitignore`)
- `.kamal/secrets`
- `.env*` files

## Troubleshooting

**Deployment fails with authentication error**:
- Check `.kamal/secrets` has correct `KAMAL_REGISTRY_PASSWORD`

**500 errors on app**:
- Check `RAILS_MASTER_KEY` in `.kamal/secrets` matches production.key
- View logs: `kamal app logs`

**Emails not sending**:
- Verify Resend API key is correct
- Check Resend domain is verified
- Check DNS records for verify.redtape.la

**SSL certificate issues**:
- Ensure DNS is pointing to correct server
- Wait a few minutes for Let's Encrypt provisioning
- Check: `kamal traefik logs`
