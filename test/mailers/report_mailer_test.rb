require "test_helper"

class ReportMailerTest < ActionMailer::TestCase
  test "verification" do
    report = reports(:one)
    mail = ReportMailer.verification(report)
    assert_equal "Verify your Red Tape Report", mail.subject
    assert_equal [ report.email ], mail.to
    assert_equal [ "reports@verify.redtape.la" ], mail.from
    assert_match report.verification_token, mail.body.encoded
  end
end
