# Security Improvements - Red Tape LA

This document outlines the security improvements implemented to address critical vulnerabilities in the application.

## Date: 2024

## Critical Issues Addressed

### 1. Content Security Policy (CSP) Enabled ✅

**Issue:** CSP was completely disabled, leaving the application vulnerable to XSS attacks.

**Fix:** Enabled CSP with appropriate policies for the application's needs.

**Location:** `config/initializers/content_security_policy.rb`

**Configuration:**
- `default_src`: Self and HTTPS only
- `font_src`: Self, HTTPS, Google Fonts
- `script_src`: Self, HTTPS, Plausible analytics
- `style_src`: Self, HTTPS, Google Fonts
- `connect_src`: Self, HTTPS, Plausible analytics
- Nonce-based inline script/style protection enabled

**Changes Made:**
1. Enabled CSP configuration in initializer
2. Added nonces to inline Plausible analytics script in `app/views/layouts/application.html.erb`
3. Removed inline styles from views and replaced with CSS classes:
   - `app/views/layouts/application.html.erb` - Flash message containers
   - `app/views/reports/success.html.erb` - Success page styles
   - `app/views/shared/_footer.html.erb` - Brand name color
   - `app/views/admin/reports/index.html.erb` - Admin dashboard styles
4. Added utility CSS classes in `app/assets/stylesheets/application.css`
5. Added admin-specific styles in `app/assets/stylesheets/admin.css`

**Email Templates Exception:**
Note: Email templates (`app/views/report_mailer/verification.html.erb`) still use inline styles as this is required for email client compatibility. This is acceptable as email content is not subject to browser CSP.

### 2. Admin Authorization Verified ✅

**Issue:** Need to verify admin authorization is properly implemented.

**Status:** VERIFIED - Authorization is correctly implemented.

**Location:** `app/controllers/admin/base_controller.rb`

**Implementation:**
```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end
end
```

**How it Works:**
1. All admin controllers inherit from `Admin::BaseController`
2. `before_action :require_admin` runs before every admin action
3. Uses `Current.user` which delegates to `Current.session.user`
4. Checks the `admin` boolean flag on the User model
5. Redirects non-admin users to root with "Access denied" alert

**User Flow:**
- `Current` (ActiveSupport::CurrentAttributes) stores session per request
- `Session` belongs to `User`
- `User` has `admin` boolean field (default: false)
- Authentication system properly sets `Current.session`

## Testing Recommendations

### Test CSP

1. **Check CSP Headers:**
```bash
curl -I https://redtape.la
# Look for: Content-Security-Policy header
```

2. **Test in Browser:**
- Open browser DevTools → Console
- Look for CSP violation warnings (there should be none)
- Try to execute inline script in console (should be blocked)

3. **Verify Plausible Still Works:**
- Check browser Network tab for plausible.io requests
- Verify analytics are being recorded

### Test Admin Authorization

1. **Create Admin User:**
```bash
# In Rails console
rails console
User.create!(
  email_address: "admin@example.com",
  password: "secure_password",
  admin: true
)
```

2. **Test Unauthorized Access:**
- Create a regular (non-admin) user
- Log in as regular user
- Try to access `/admin/reports`
- Should redirect to root with "Access denied" message

3. **Test Authorized Access:**
- Log in as admin user
- Access `/admin/reports`
- Should successfully display admin dashboard

## Additional Security Measures Already in Place

- ✅ Rate limiting via Rack::Attack (5 submissions/IP/hour, 3/email/day)
- ✅ Email verification required for all reports
- ✅ CSRF protection enabled (Rails default)
- ✅ SSL/TLS enforced in production
- ✅ Secure session cookies (httponly, same_site)
- ✅ Password hashing with bcrypt
- ✅ Soft deletes (data preservation)

## Remaining Recommendations

### High Priority
1. **Migrate from SQLite to PostgreSQL**
   - SQLite is not suitable for production with concurrent writes
   - Risk of database locking and data loss
   - Recommendation: Use PostgreSQL with proper backups

2. **Add Database Indexes**
   ```ruby
   # Migration needed:
   add_index :reports, :email
   add_index :reports, :created_at
   ```

3. **Implement Comprehensive Tests**
   - Test admin authorization logic
   - Test report verification flow
   - Test rate limiting
   - Test CSP policies

### Medium Priority
4. **Add Rack::Attack Custom Response**
   ```ruby
   # config/initializers/rack_attack.rb
   Rack::Attack.throttled_responder = lambda do |request|
     [429, {}, ["Too many submissions. Please try again later."]]
   end
   ```

5. **Standardize Contact Email**
   - Currently using both `john@redtape.la` and `hello@redtape.la`
   - Pick one and update all references

6. **Add Admin Action Logging**
   - Track who approves/deletes reports
   - Create `AdminAction` model for audit trail

7. **Setup Background Job Monitoring**
   - Monitor Solid Queue for failed jobs
   - Alert on failed verification emails

### Low Priority
8. **Add Honeypot Field**
   - Additional spam protection beyond rate limiting

9. **Implement Report-Only CSP Mode First**
   - Test in production without blocking
   - Review violations before enforcing

10. **Add Database Backup Strategy**
    - Automated backups for production data
    - Document recovery procedures

## Environment Variables Required

Ensure these are set in production:

```bash
# Required
RESEND_API_KEY=your_resend_api_key
SECRET_KEY_BASE=your_secret_key

# Optional but recommended
RAILS_LOG_LEVEL=info
RAILS_ENV=production
```

## Deployment Checklist

Before deploying these changes:

- [ ] Test CSP in staging environment first
- [ ] Verify Plausible analytics still works
- [ ] Test admin login flow
- [ ] Test regular user cannot access admin routes
- [ ] Check for CSP violations in browser console
- [ ] Verify all pages load correctly
- [ ] Test form submissions still work
- [ ] Verify email templates display correctly

## Files Modified

### Security Configuration
- `config/initializers/content_security_policy.rb` - Enabled CSP

### Views (Removed Inline Styles)
- `app/views/layouts/application.html.erb` - Added nonces, removed inline styles
- `app/views/reports/success.html.erb` - Replaced inline styles with classes
- `app/views/shared/_footer.html.erb` - Removed inline style
- `app/views/admin/reports/index.html.erb` - Replaced inline styles with classes
- `app/views/report_mailer/verification.html.erb` - Fixed quotes (inline styles OK for email)

### Stylesheets
- `app/assets/stylesheets/application.css` - Added utility classes
- `app/assets/stylesheets/admin.css` - Added filter tab and stat card styles

## Rollback Plan

If issues arise after deployment:

1. **Disable CSP temporarily:**
   ```ruby
   # config/initializers/content_security_policy.rb
   config.content_security_policy_report_only = true
   ```

2. **Monitor logs for CSP violations:**
   ```bash
   # Production logs will show CSP violations
   tail -f log/production.log | grep "CSP"
   ```

3. **Revert if critical issues:**
   ```bash
   git revert <commit_hash>
   # Redeploy previous version
   ```

## Questions or Issues?

Contact: john@redtape.la

## Future Security Enhancements

Consider implementing:
- Two-factor authentication for admin users
- Rate limiting per user account (in addition to IP/email)
- Automated security scanning (Brakeman already configured)
- Regular dependency updates and vulnerability scanning
- Session timeout for admin users
- IP whitelist for admin access (if feasible)