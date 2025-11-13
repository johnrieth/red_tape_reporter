class AdminNotificationMailer < ApplicationMailer
  # Send notification to admins when a new report is verified
  def new_verified_report(report)
    @report = report
    @admin_url = admin_report_url(@report)

    # Get admin emails from environment variable
    # Format: ADMIN_NOTIFICATION_EMAILS="admin1@example.com,admin2@example.com"
    admin_emails = ENV.fetch("ADMIN_NOTIFICATION_EMAILS", "").split(",").map(&:strip).reject(&:blank?)

    # Fallback to all admin users if no env var is set
    if admin_emails.empty?
      admin_emails = User.where(admin: true).pluck(:email_address)
    end

    return if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "New Verified Report: #{@report.project_type} in #{@report.location}"
    )
  end
end
