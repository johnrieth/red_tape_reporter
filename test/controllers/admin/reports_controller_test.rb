require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @regular_user = users(:regular_user)
  end

  # ============================================================
  # AUTHENTICATION TESTS
  # ============================================================

  test "should require authentication for index" do
    get admin_reports_path
    assert_redirected_to new_session_path
  end

  test "should require admin for index" do
    sign_in_as(@regular_user)
    get admin_reports_path
    assert_redirected_to root_path
  end

  test "admin should access index" do
    sign_in_as(@admin)
    get admin_reports_path
    assert_response :success
  end

  # ============================================================
  # INDEX ACTION TESTS
  # ============================================================

  test "index should display all reports by default" do
    sign_in_as(@admin)
    get admin_reports_path
    assert_response :success
    assert_not_nil assigns(:reports)
  end

  test "index should filter by pending_review status" do
    sign_in_as(@admin)
    get admin_reports_path, params: { filter: "pending_review" }
    assert_response :success

    pending_report = reports(:pending_report)
    approved_report = reports(:approved_report)

    assert_includes assigns(:reports), pending_report
    assert_not_includes assigns(:reports), approved_report
  end

  test "index should filter by approved status" do
    sign_in_as(@admin)
    get admin_reports_path, params: { filter: "approved" }
    assert_response :success

    pending_report = reports(:pending_report)
    approved_report = reports(:approved_report)

    assert_includes assigns(:reports), approved_report
    assert_not_includes assigns(:reports), pending_report
  end

  test "index should filter by unverified status" do
    sign_in_as(@admin)
    get admin_reports_path, params: { filter: "unverified" }
    assert_response :success

    unverified_report = reports(:unverified_report)
    verified_report = reports(:approved_report)

    assert_includes assigns(:reports), unverified_report
    assert_not_includes assigns(:reports), verified_report
  end

  test "index should exclude deleted reports" do
    sign_in_as(@admin)
    get admin_reports_path
    deleted_report = reports(:deleted_report)
    assert_not_includes assigns(:reports), deleted_report
  end

  test "index should display statistics" do
    sign_in_as(@admin)
    get admin_reports_path
    assert_not_nil assigns(:total_approved)
    assert_not_nil assigns(:pending_review_count)
    assert_not_nil assigns(:unverified_count)
  end

  # ============================================================
  # SHOW ACTION TESTS
  # ============================================================

  test "should show report when admin" do
    sign_in_as(@admin)
    get admin_report_path(reports(:approved_report))
    assert_response :success
    assert_not_nil assigns(:report)
  end

  # ============================================================
  # APPROVE ACTION TESTS
  # ============================================================

  test "should approve report" do
    sign_in_as(@admin)
    report = reports(:pending_report)
    assert_nil report.approved_at

    patch approve_admin_report_path(report)
    report.reload
    assert_not_nil report.approved_at
    assert_redirected_to admin_reports_path(filter: "pending_review")
  end

  test "approve should update status to approved" do
    sign_in_as(@admin)
    report = reports(:pending_report)

    patch approve_admin_report_path(report)
    report.reload
    assert_equal "approved", report.status
  end

  # ============================================================
  # DESTROY ACTION TESTS
  # ============================================================

  test "should soft delete report" do
    sign_in_as(@admin)
    report = reports(:approved_report)
    assert_nil report.deleted_at

    delete admin_report_path(report)
    report.reload
    assert_not_nil report.deleted_at
    assert_redirected_to admin_reports_path(filter: "pending_review")
  end

  test "destroy should not hard delete report" do
    sign_in_as(@admin)
    report = reports(:approved_report)

    assert_no_difference("Report.count") do
      delete admin_report_path(report)
    end
  end

  # ============================================================
  # EXPORT ACTION TESTS
  # ============================================================

  test "should export reports as CSV" do
    sign_in_as(@admin)
    get export_admin_reports_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match /red-tape-reports-.*\.csv/, response.headers["Content-Disposition"]
  end

  test "should export reports as PDF" do
    sign_in_as(@admin)
    get export_admin_reports_path(format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "CSV export should include report data" do
    sign_in_as(@admin)
    get export_admin_reports_path(format: :csv)

    csv_content = response.body
    assert_includes csv_content, "Report ID"
    assert_includes csv_content, "Project Type"
    assert_includes csv_content, "Location"
  end

  test "export should filter by date range" do
    sign_in_as(@admin)
    start_date = 1.week.ago.to_date
    end_date = Date.today

    get export_admin_reports_path(
      format: :csv,
      start_date: start_date.to_s,
      end_date: end_date.to_s
    )

    assert_response :success
  end

  test "export should only include approved reports" do
    sign_in_as(@admin)

    # Create a pending report that shouldn't appear in export
    pending = reports(:pending_report)
    approved = reports(:approved_report)

    get export_admin_reports_path(format: :csv)
    csv_content = response.body

    # CSV should include approved report ID
    assert_includes csv_content, approved.id.to_s
  end
end
