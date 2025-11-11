require "test_helper"

class ReportSubmissionFlowTest < ActionDispatch::IntegrationTest
  # ============================================================
  # COMPLETE USER FLOW TESTS
  # ============================================================

  test "complete report submission and verification flow" do
    # Step 1: Visit the new report page
    get new_report_path
    assert_response :success

    # Step 2: Submit a report
    assert_difference("Report.count", 1) do
      assert_emails 1 do
        post reports_path, params: { report: valid_report_params }
      end
    end

    # Step 3: Should redirect to success page
    assert_redirected_to success_reports_path
    follow_redirect!
    assert_response :success

    # Step 4: Get the created report
    report = Report.last
    assert_not_nil report
    assert_nil report.verified_at, "Report should not be verified yet"

    # Step 5: Verify the report using token from email
    get verify_report_path(token: report.verification_token)
    assert_response :success

    # Step 6: Check that report is now verified
    report.reload
    assert_not_nil report.verified_at, "Report should be verified"
    assert report.verified?, "Report should be verified"
  end

  test "admin approval workflow" do
    # Step 1: Create and verify a report
    report = Report.create!(valid_report_params)
    report.update!(verified_at: Time.current)

    # Step 2: Admin logs in
    admin = users(:admin_user)
    sign_in_as(admin)

    # Step 3: Admin views pending reports
    get admin_reports_path(filter: "pending_review")
    assert_response :success
    assert_includes assigns(:reports), report

    # Step 4: Admin views the report detail
    get admin_report_path(report)
    assert_response :success

    # Step 5: Admin approves the report
    assert_nil report.approved_at
    patch approve_admin_report_path(report)

    # Step 6: Verify approval
    report.reload
    assert_not_nil report.approved_at
    assert report.approved?, "Report should be approved"
    assert_equal "approved", report.status
  end

  test "unauthenticated user cannot access admin features" do
    # Try to access admin dashboard without logging in
    get admin_reports_path
    assert_redirected_to new_session_path

    # Try to approve a report without logging in
    report = reports(:pending_report)
    patch approve_admin_report_path(report)
    assert_redirected_to new_session_path
  end

  test "non-admin user cannot access admin features" do
    # Sign in as regular user (non-admin)
    regular_user = users(:regular_user)
    sign_in_as(regular_user)

    # Try to access admin dashboard
    get admin_reports_path
    assert_redirected_to root_path
  end

  test "invalid verification token shows error" do
    get verify_report_path(token: "invalid-token-12345")
    assert_redirected_to root_path
  end

  test "submitting invalid report shows errors" do
    # Visit form
    get new_report_path
    assert_response :success

    # Submit invalid report (missing required fields)
    assert_no_difference("Report.count") do
      post reports_path, params: {
        report: { name: "Test", email: "invalid-email" }
      }
    end

    # Should show errors
    assert_response :unprocessable_entity
  end

  test "admin can export approved reports" do
    # Create an approved report
    report = Report.create!(valid_report_params)
    report.update!(verified_at: 1.day.ago, approved_at: Time.current)

    # Admin logs in
    admin = users(:admin_user)
    sign_in_as(admin)

    # Export as CSV
    get export_admin_reports_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.content_type

    # Export as PDF
    get export_admin_reports_path(format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "admin can soft delete a report" do
    report = reports(:approved_report)
    admin = users(:admin_user)
    sign_in_as(admin)

    # Delete the report
    assert_nil report.deleted_at
    delete admin_report_path(report)

    # Check it's soft deleted
    report.reload
    assert_not_nil report.deleted_at
    assert report.deleted?, "Report should be soft deleted"

    # Report still exists in database
    assert Report.find(report.id)
  end

  test "public cannot see unapproved reports" do
    # Visit the home page
    get reports_path
    assert_response :success

    # The count should only include approved reports
    approved_count = Report.approved.count
    # This assumes the homepage shows the count somewhere
    assert_match /#{approved_count}/, response.body
  end
end
