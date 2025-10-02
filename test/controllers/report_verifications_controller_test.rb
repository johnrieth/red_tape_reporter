require "test_helper"

class ReportVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "should verify report with valid token" do
    report = reports(:one)
    report.update!(verified_at: nil)  # Ensure it's not already verified
    get verify_report_path(report.verification_token)
    assert_response :success
    report.reload
    assert_not_nil report.verified_at
    assert_equal "verified", report.status
  end
end
