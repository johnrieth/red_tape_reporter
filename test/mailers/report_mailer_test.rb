require "test_helper"

class ReportMailerTest < ActionMailer::TestCase
  # ============================================================
  # VERIFICATION EMAIL TESTS
  # ============================================================

  test "verification email is sent to correct recipient" do
    report = reports(:unverified_report)
    email = ReportMailer.verification(report)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ report.email ], email.to
  end

  test "verification email has correct subject" do
    report = reports(:unverified_report)
    email = ReportMailer.verification(report)

    assert_equal "Verify your Red Tape Report", email.subject
  end

  test "verification email has correct from address" do
    report = reports(:unverified_report)
    email = ReportMailer.verification(report)

    assert_equal [ "reports@verify.redtape.la" ], email.from
  end

  test "verification email includes verification token" do
    report = reports(:unverified_report)
    email = ReportMailer.verification(report)

    assert_match report.verification_token, email.body.encoded,
      "Email should include verification token"
  end

  test "verification email includes verification URL" do
    report = reports(:unverified_report)
    email = ReportMailer.verification(report)

    # Should include verify in the URL
    assert_match /verify/, email.body.encoded, "Email should include verify URL"
    assert_match report.verification_token, email.body.encoded,
      "Email should include verification token in URL"
  end

  test "verification email can be sent for any report" do
    # Test with different reports
    [ reports(:approved_report), reports(:pending_report), reports(:unverified_report) ].each do |report|
      email = ReportMailer.verification(report)

      assert_not_nil email
      assert_equal [ report.email ], email.to
      assert_match report.verification_token, email.body.encoded
    end
  end
end
