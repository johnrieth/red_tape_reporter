require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_report_path
    assert_response :success
  end

  test "should create report" do
    assert_difference("Report.count") do
      post reports_path, params: {
        report: {
          name: "Test User",
          email: "test@example.com",
          project_description: "This is a test construction project for a new building",
          issue_description: "Experiencing significant delays with permit approvals and inspections",
          project_type: "New construction",
          location: "Los Angeles",
          issue_categories: ["Permits"],
          departments: ["Building & Safety"],
          timeline_impact: "Less than 3 months",
          financial_impact: "$1,000-$10,000"
        }
      }
    end
    assert_redirected_to success_reports_path
  end
end
