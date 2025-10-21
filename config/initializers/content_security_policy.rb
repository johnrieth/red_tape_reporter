# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data, "fonts.googleapis.com", "fonts.gstatic.com"
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, "plausible.io"
    policy.style_src   :self, :https, :unsafe_inline, "fonts.googleapis.com"
    policy.style_src_attr :unsafe_inline  # Allow Turbo to add inline style attributes
    policy.connect_src :self, :https, "plausible.io"

    # Specify URI for violation reports (optional)
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # Uncomment this line during initial testing to see violations without blocking content
  # config.content_security_policy_report_only = true
end
