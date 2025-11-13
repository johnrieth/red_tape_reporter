require "test_helper"

class AdminNotificationMailerTest < ActionMailer::TestCase
  test "new_verified_report creates email with report details" do
    report = reports(:pending_report)
    mail = AdminNotificationMailer.new_verified_report(report)

    # Test email structure and content
    assert_equal "New Verified Report: #{report.project_type} in #{report.location}", mail.subject
    assert_equal [ "reports@verify.redtape.la" ], mail.from
    assert_match report.project_type, mail.body.encoded
    assert_match report.location, mail.body.encoded
    assert_match report.issue_description, mail.body.encoded

    # Verify email has recipients (either from credentials or fallback to admin users)
    assert mail.to.present?, "Email should have recipients"
    assert mail.to.is_a?(Array), "Recipients should be an array"
  end

  test "new_verified_report includes admin URL in email" do
    report = reports(:pending_report)
    mail = AdminNotificationMailer.new_verified_report(report)

    # Verify the admin URL is included
    assert_match %r{/admin/reports/#{report.id}}, mail.body.encoded
  end
end
