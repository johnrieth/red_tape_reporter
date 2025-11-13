class AdminNotificationMailer < ApplicationMailer
  # Send notification to admins when a new report is verified
  def new_verified_report(report)
    @report = report
    @admin_url = admin_report_url(@report)

    admin_emails = get_admin_emails

    return if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "New Verified Report: #{@report.project_type} in #{@report.location}"
    )
  end

  private

  # Get admin emails from Rails credentials
  # Format in credentials.yml.enc:
  #   resend:
  #     admin_notification_emails:
  #       - admin1@example.com
  #       - admin2@example.com
  def get_admin_emails
    admin_emails = Rails.application.credentials.dig(:resend, :admin_notification_emails) || []
    admin_emails = Array(admin_emails).compact.map(&:strip).reject(&:blank?)

    # Fallback to all admin users if no credentials are set
    if admin_emails.empty?
      admin_emails = User.where(admin: true).pluck(:email_address)
    end

    admin_emails
  end
end
