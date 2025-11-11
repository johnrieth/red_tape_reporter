require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  # ============================================================
  # INDEX ACTION TESTS
  # ============================================================

  test "should get index" do
    get reports_path
    assert_response :success
  end

  test "index should show page title" do
    get reports_path
    assert_response :success
    # Should show the heading
    assert_select "h1"
  end

  # ============================================================
  # NEW ACTION TESTS
  # ============================================================

  test "should get new" do
    get new_report_path
    assert_response :success
  end

  test "new should display report form" do
    get new_report_path
    assert_select "form"
    assert_select "input[name=?]", "report[email]"
    assert_select "textarea[name=?]", "report[project_description]"
    assert_select "textarea[name=?]", "report[issue_description]"
  end

  # ============================================================
  # CREATE ACTION TESTS
  # ============================================================

  test "should create report with valid params" do
    assert_difference("Report.count", 1) do
      post reports_path, params: { report: valid_report_params }
    end
    assert_redirected_to success_reports_path
  end

  test "should send verification email after creating report" do
    assert_emails 1 do
      post reports_path, params: { report: valid_report_params }
    end
  end

  test "created report should be unverified by default" do
    post reports_path, params: { report: valid_report_params }
    report = Report.last
    assert_nil report.verified_at, "New report should not be verified"
  end

  test "created report should be anonymous by default" do
    post reports_path, params: { report: valid_report_params }
    report = Report.last
    assert report.anonymous?, "New report should be anonymous"
  end

  test "should not create report with invalid email" do
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: valid_report_params.merge(email: "invalid-email")
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create report with missing required fields" do
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: { name: "Test", email: "test@example.com" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create report with short project_description" do
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: valid_report_params.merge(project_description: "Short")
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create report with short issue_description" do
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: valid_report_params.merge(issue_description: "Short")
      }
    end
    assert_response :unprocessable_entity
  end

  test "should render errors when validation fails" do
    post reports_path, params: {
      report: valid_report_params.merge(email: "invalid")
    }
    assert_response :unprocessable_entity
    assert_select ".alert-error", minimum: 1
  end

  # ============================================================
  # SUCCESS ACTION TESTS
  # ============================================================

  test "should get success page" do
    get success_reports_path
    assert_response :success
  end
end
