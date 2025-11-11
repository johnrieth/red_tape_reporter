require "test_helper"

class ReportVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "should verify report with valid token" do
    report = reports(:unverified_report)
    assert_nil report.verified_at, "Report should not be verified initially"

    get verify_report_path(report.verification_token)
    assert_response :success

    report.reload
    assert_not_nil report.verified_at, "Report should be verified after verification"
    assert_equal "verified", report.status
  end
end
