require "test_helper"

class AdminNotificationMailerTest < ActionMailer::TestCase
  test "new_verified_report sends email to admin with report details" do
    # Set up environment variable for testing
    ENV["ADMIN_NOTIFICATION_EMAILS"] = "admin@example.com,admin2@example.com"

    report = reports(:pending_report)
    mail = AdminNotificationMailer.new_verified_report(report)

    assert_equal "New Verified Report: #{report.project_type} in #{report.location}", mail.subject
    assert_equal [ "admin@example.com", "admin2@example.com" ], mail.to
    assert_equal [ "reports@verify.redtape.la" ], mail.from
    assert_match report.project_type, mail.body.encoded
    assert_match report.location, mail.body.encoded
    assert_match report.issue_description, mail.body.encoded
  ensure
    # Clean up
    ENV.delete("ADMIN_NOTIFICATION_EMAILS")
  end

  test "new_verified_report falls back to admin users when no env var set" do
    # Make sure env var is not set
    ENV.delete("ADMIN_NOTIFICATION_EMAILS")

    report = reports(:pending_report)
    mail = AdminNotificationMailer.new_verified_report(report)

    # Should send to all admin users
    admin_emails = User.where(admin: true).pluck(:email_address)
    assert_equal admin_emails, mail.to
  end
end
