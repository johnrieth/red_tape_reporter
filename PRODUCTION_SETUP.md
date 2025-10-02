# Production Setup Checklist

## 1. Create Production Credentials

Run this command to create and edit your production credentials:

```bash
EDITOR=vim rails credentials:edit --environment production
```

Add the following content:

```yaml
resend:
  api_key: YOUR_RESEND_API_KEY_HERE

secret_key_base: # This will be auto-generated
```

The file will be encrypted and saved to `config/credentials/production.yml.enc`
Make sure to keep the production master key (`config/credentials/production.key`) secure!

## 2. Update Kamal Deployment Configuration

Edit `config/deploy.yml` and update these values:

- **Line 5**: Change `image: your-user/red_tape_reporter` to your Docker registry path
  - Example: `image: ghcr.io/yourusername/red_tape_reporter`
  - Or: `image: yourdockerhubuser/red_tape_reporter`

- **Line 10**: Change server IP from `192.168.0.1` to your actual server IP
  - Example: `- 123.456.789.012`

- **Line 22**: Change `host: app.example.com` to `host: verify.redtape.la`

- **Line 28**: Change `username: your-user` to your Docker registry username

## 3. Set Up Kamal Secrets

Edit `.kamal/secrets` and ensure it contains:

```bash
KAMAL_REGISTRY_PASSWORD=<your-docker-registry-password>
RAILS_MASTER_KEY=<content-of-config/credentials/production.key>
```

## 4. Get a Resend API Key

1. Sign up at https://resend.com
2. Create an API key
3. Verify your domain `redtape.la` in Resend
4. Add the API key to your production credentials (step 1)

## 5. Server Setup

Make sure your production server has:
- Docker installed
- SSH access configured
- Port 80 and 443 open in firewall
- DNS pointing verify.redtape.la to the server IP

## 6. Deploy

Once all the above is complete:

```bash
# Initial setup (first time only)
kamal setup

# Or for updates
kamal deploy
```

## 7. Post-Deployment

After deployment:

```bash
# Check app status
kamal app logs

# Run database migrations if needed
kamal app exec 'bin/rails db:migrate'

# Check app is running
curl https://verify.redtape.la/up
```

## Security Notes

- ✅ SSL/HTTPS is enabled
- ✅ Host authorization is enabled for verify.redtape.la
- ✅ Rate limiting is configured (5 reports per IP per hour)
- ✅ Force SSL is enabled
- ✅ Cookies are secure
- ✅ Running as non-root user in Docker
- ✅ Email verification required for reports
