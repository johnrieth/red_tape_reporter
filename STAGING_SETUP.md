# Staging Environment Setup Guide

## Do You Need Staging?

**Short answer:** Not necessarily! For a small project like Red Tape LA, testing locally is often sufficient.

**When to use staging:**
- You want to test with production-like infrastructure (SSL, domain, etc.)
- You want to test email delivery with real domains
- You have a team and want a shared testing environment
- You want to test deployments before going to production

**When local testing is fine:**
- Solo developer (you!)
- Changes are low-risk (like the CSP/security changes we just made)
- You have good test coverage
- Quick iteration is more important than perfect replication

## Option 1: Test Locally (Recommended for Now)

This is the fastest and easiest way to test the security changes:

### Step 1: Start Your Local Server

```bash
# From project directory
cd red_tape_reporter

# Install dependencies (if needed)
bundle install

# Start the server
rails server
```

Open http://localhost:3000 in your browser.

### Step 2: Create a Test Admin User

```bash
# In another terminal
EMAIL=admin@test.com PASSWORD=password123 rails admin:create
```

### Step 3: Test Everything

**Test CSP is working:**
1. Open browser DevTools (F12)
2. Go to Console tab
3. Browse around the site
4. Look for CSP errors → Should be NONE
5. Check Network tab → Plausible should load from plausible.io

**Test report submission:**
1. Go to http://localhost:3000
2. Click "Share Your Story"
3. Fill out the form
4. Submit
5. Check terminal for email delivery logs

**Test admin authorization:**
1. Go to http://localhost:3000/session/new
2. Log in with admin@test.com / password123
3. Go to http://localhost:3000/admin/reports → Should work
4. Log out
5. Try to access http://localhost:3000/admin/reports → Should redirect with "Access denied"

**Test as non-admin:**
```bash
# Create regular user (not admin)
EMAIL=user@test.com PASSWORD=password123 rails runner "User.create!(email_address: 'user@test.com', password: 'password123', admin: false)"
```

1. Log in as user@test.com
2. Try to access /admin/reports → Should be blocked

### Step 4: Run Tests

```bash
# Run test suite
rails test

# Run security scan
bundle exec brakeman

# Check for any rubocop issues (optional)
bundle exec rubocop
```

If everything works locally, **you're ready to deploy to production!**

---

## Option 2: Set Up a Staging Server (Advanced)

Only do this if you really want a staging environment.

### Prerequisites

You need:
- A second server (can be smaller/cheaper than production)
- A subdomain for staging (e.g., staging.redtape.la)
- SSH access to the staging server
- Docker installed on staging server

### Step 1: Get a Staging Server

**Option A: Same Hetzner account**
- Create another server (CX11 is fine - $4/month)
- Use same SSH key as production
- Note the IP address

**Option B: Use existing server on different port**
- Can deploy to same server as production
- Different container name (`red_tape_reporter_staging`)
- Different port mapping

**Option C: Use a free/cheap service**
- Render.com free tier
- Railway.app free tier
- Fly.io free tier

### Step 2: DNS Setup

Add a subdomain pointing to your staging server:

```
staging.redtape.la  →  A record  →  YOUR_STAGING_SERVER_IP
```

Wait for DNS to propagate (can take a few minutes to 24 hours).

### Step 3: Create Staging Credentials

```bash
# Create staging credentials
EDITOR=vim rails credentials:edit --environment staging
```

Add your Resend API key:
```yaml
resend:
  api_key: re_YourResendApiKey_Here
```

Save and exit. This creates:
- `config/credentials/staging.yml.enc` (safe to commit)
- `config/credentials/staging.key` (DO NOT COMMIT)

### Step 4: Update Staging Deploy Config

Edit `config/deploy.staging.yml`:

```yaml
servers:
  web:
    - YOUR_STAGING_SERVER_IP  # Replace with actual IP

proxy:
  host: staging.redtape.la  # Your staging subdomain
```

### Step 5: Update Kamal Secrets

Edit `.kamal/secrets` and add staging secrets:

```bash
# Existing production secrets
KAMAL_REGISTRY_PASSWORD=your_github_token
RAILS_MASTER_KEY=your_production_master_key

# Add staging secrets
STAGING_RAILS_MASTER_KEY=paste_content_of_config_credentials_staging_key_here
```

Update `.kamal/secrets` to use the staging key when deploying to staging:

```bash
#!/bin/sh

# Decide which environment based on config file being used
if [ "$KAMAL_CONFIG" = "config/deploy.staging.yml" ]; then
  echo "RAILS_MASTER_KEY=$STAGING_RAILS_MASTER_KEY"
else
  echo "RAILS_MASTER_KEY=$RAILS_MASTER_KEY"
fi

echo "KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD"
```

### Step 6: Deploy to Staging

```bash
# First time setup
kamal setup -d staging

# Or regular deploy
kamal deploy -d staging
```

The `-d staging` flag tells Kamal to use `config/deploy.staging.yml`.

### Step 7: Create Staging Admin User

```bash
# Access staging console
kamal app exec -d staging --interactive "bin/rails console"

# In the console:
User.create!(
  email_address: "admin@example.com",
  password: "staging_password",
  admin: true
)
```

### Step 8: Test on Staging

Visit https://staging.redtape.la and test everything:

- [ ] Site loads with valid SSL
- [ ] No CSP errors in browser console
- [ ] Can submit reports
- [ ] Verification emails arrive
- [ ] Admin can access /admin/reports
- [ ] Non-admin blocked from admin area
- [ ] Plausible analytics loads

### Staging Commands Reference

```bash
# Deploy to staging
kamal deploy -d staging

# View staging logs
kamal app logs -d staging -f

# Access staging console
kamal app exec -d staging --interactive "bin/rails console"

# SSH into staging server
kamal app exec -d staging --interactive "bash"

# Restart staging app
kamal app restart -d staging

# Check staging status
kamal app details -d staging
```

---

## Recommended Approach for Security Changes

For the CSP and admin authorization changes we just made:

1. **Test locally first** (Option 1)
   - Fastest and easiest
   - Catches 95% of issues
   - No extra infrastructure needed

2. **Review the changes**
   - Look at the code changes
   - Understand what CSP does
   - Verify admin auth logic

3. **Run tests**
   ```bash
   rails test
   bundle exec brakeman
   ```

4. **Deploy to production**
   - These changes are low-risk
   - No database migrations
   - Easily reversible if needed

5. **Monitor after deployment**
   ```bash
   # Watch production logs
   kamal app logs -f
   
   # Check for CSP violations
   kamal app logs | grep -i "csp"
   ```

6. **Have a rollback plan**
   - If issues arise, disable CSP temporarily:
   ```ruby
   # config/initializers/content_security_policy.rb
   config.content_security_policy_report_only = true
   ```
   - Redeploy with `kamal deploy`

---

## Cost Comparison

**Local Testing:**
- Cost: $0
- Time to setup: 2 minutes
- Good enough for: 90% of changes

**Staging Server:**
- Cost: $4-10/month (Hetzner CX11, DigitalOcean droplet, etc.)
- Time to setup: 30-60 minutes
- Good enough for: Testing with real SSL, emails, domains

**My Recommendation:**

For your current security changes:
1. Test locally (5 minutes)
2. Deploy to production (5 minutes)
3. Monitor logs (5 minutes)

Total time: 15 minutes vs. 1+ hour to set up staging.

Save staging setup for when you:
- Have paying customers
- Need to test complex infrastructure changes
- Have a team that needs a shared environment
- Are making risky database migrations

---

## Quick Start: Test Now

The absolute fastest way to verify your changes are ready:

```bash
# 1. Start server
rails server

# 2. Open browser to http://localhost:3000

# 3. Check console (F12) for errors → Should see none

# 4. Create admin user
EMAIL=admin@test.com PASSWORD=test123 rails admin:create

# 5. Test admin login at http://localhost:3000/session/new

# 6. Run tests
rails test
```

If all that works → **Deploy to production!**

```bash
# Deploy
kamal deploy

# Watch logs
kamal app logs -f

# Test live site
curl -I https://redtape.la | grep "Content-Security-Policy"
```

Done! 🎉

---

## Questions?

- **Should I set up staging?** Probably not needed right now. Test locally.
- **Is local testing enough?** Yes, for these security changes.
- **When should I set up staging?** When you have complex infrastructure or a team.
- **What if something breaks?** Disable CSP temporarily and redeploy.

Contact: john@redtape.la