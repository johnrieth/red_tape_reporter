require "test_helper"

class ReportTest < ActiveSupport::TestCase
  # ============================================================
  # VALIDATION TESTS
  # ============================================================

  test "should save valid report" do
    report = Report.new(valid_report_params)
    assert report.save, "Valid report should save successfully"
  end

  test "should not save report without email" do
    report = Report.new(valid_report_params.merge(email: nil))
    assert_not report.save, "Report should not save without email"
    assert_includes report.errors[:email], "can't be blank"
  end

  test "should not save report with invalid email format" do
    report = Report.new(valid_report_params.merge(email: "invalid-email"))
    assert_not report.save, "Report should not save with invalid email"
    assert_includes report.errors[:email], "is invalid"
  end

  test "should not save report without project_type" do
    report = Report.new(valid_report_params.merge(project_type: nil))
    assert_not report.save
    assert_includes report.errors[:project_type], "can't be blank"
  end

  test "should not save report without project_description" do
    report = Report.new(valid_report_params.merge(project_description: nil))
    assert_not report.save
    assert_includes report.errors[:project_description], "can't be blank"
  end

  test "should not save report with short project_description" do
    report = Report.new(valid_report_params.merge(project_description: "Too short"))
    assert_not report.save
    assert_includes report.errors[:project_description], "is too short (minimum is 10 characters)"
  end

  test "should not save report without location" do
    report = Report.new(valid_report_params.merge(location: nil))
    assert_not report.save
    assert_includes report.errors[:location], "can't be blank"
  end

  test "should not save report without issue_description" do
    report = Report.new(valid_report_params.merge(issue_description: nil))
    assert_not report.save
    assert_includes report.errors[:issue_description], "can't be blank"
  end

  test "should not save report with short issue_description" do
    report = Report.new(valid_report_params.merge(issue_description: "Short"))
    assert_not report.save
    assert_includes report.errors[:issue_description], "is too short (minimum is 20 characters)"
  end

  # ============================================================
  # CALLBACK TESTS
  # ============================================================

  test "should generate verification token before create" do
    report = Report.new(valid_report_params)
    assert_nil report.verification_token, "Token should be nil before save"

    report.save
    assert_not_nil report.verification_token, "Token should be generated on save"
    assert report.verification_token.length > 20, "Token should be sufficiently long"
  end

  test "should generate unique verification tokens" do
    report1 = Report.create!(valid_report_params)
    report2 = Report.create!(valid_report_params.merge(email: "another@example.com"))

    assert_not_equal report1.verification_token, report2.verification_token,
      "Each report should have a unique verification token"
  end

  test "should set default values on initialization" do
    report = Report.new
    assert_equal "new", report.status
    assert_equal [], report.departments
    assert_equal [], report.issue_categories
  end

  # ============================================================
  # SCOPE TESTS
  # ============================================================

  test "not_deleted scope should exclude deleted reports" do
    active_report = reports(:approved_report)
    deleted_report = reports(:deleted_report)

    results = Report.not_deleted
    assert_includes results, active_report, "Should include active report"
    assert_not_includes results, deleted_report, "Should exclude deleted report"
  end

  test "approved scope should return only approved reports" do
    approved = reports(:approved_report)
    pending = reports(:pending_report)

    results = Report.approved
    assert_includes results, approved, "Should include approved report"
    assert_not_includes results, pending, "Should not include pending report"
  end

  test "verified scope should return only verified reports" do
    verified = reports(:approved_report)
    unverified = reports(:unverified_report)

    results = Report.verified
    assert_includes results, verified, "Should include verified report"
    assert_not_includes results, unverified, "Should not include unverified report"
  end

  test "unverified scope should return only unverified reports" do
    verified = reports(:approved_report)
    unverified = reports(:unverified_report)

    results = Report.unverified
    assert_includes results, unverified, "Should include unverified report"
    assert_not_includes results, verified, "Should not include verified report"
  end

  test "pending_review scope should return verified but not approved reports" do
    approved = reports(:approved_report)
    pending = reports(:pending_report)
    unverified = reports(:unverified_report)

    results = Report.pending_review
    assert_includes results, pending, "Should include pending report"
    assert_not_includes results, approved, "Should not include approved report"
    assert_not_includes results, unverified, "Should not include unverified report"
  end

  test "anonymous scope should return only anonymous reports" do
    report = reports(:approved_report)
    assert report.anonymous?, "Fixture should be anonymous"

    results = Report.anonymous
    assert_includes results, report
  end

  test "recent scope should order by created_at descending" do
    results = Report.recent.limit(2)
    assert results.first.created_at >= results.second.created_at,
      "Reports should be ordered newest first"
  end

  # ============================================================
  # METHOD TESTS
  # ============================================================

  test "verified? should return true when verified_at is present" do
    report = reports(:approved_report)
    assert report.verified?, "Report with verified_at should be verified"
  end

  test "verified? should return false when verified_at is nil" do
    report = reports(:unverified_report)
    assert_not report.verified?, "Report without verified_at should not be verified"
  end

  test "approved? should return true when approved_at is present" do
    report = reports(:approved_report)
    assert report.approved?, "Report with approved_at should be approved"
  end

  test "approved? should return false when approved_at is nil" do
    report = reports(:pending_report)
    assert_not report.approved?, "Report without approved_at should not be approved"
  end

  test "deleted? should return true when deleted_at is present" do
    report = reports(:deleted_report)
    assert report.deleted?, "Report with deleted_at should be deleted"
  end

  test "deleted? should return false when deleted_at is nil" do
    report = reports(:approved_report)
    assert_not report.deleted?, "Report without deleted_at should not be deleted"
  end

  test "soft_delete should set deleted_at timestamp" do
    report = reports(:approved_report)
    assert_nil report.deleted_at

    report.soft_delete
    assert_not_nil report.deleted_at, "deleted_at should be set"
    assert report.deleted?, "Report should be marked as deleted"
  end

  test "approve should set approved_at and update status" do
    report = reports(:pending_report)
    assert_nil report.approved_at
    assert_equal "new", report.status

    report.approve
    assert_not_nil report.approved_at, "approved_at should be set"
    assert_equal "approved", report.status
    assert report.approved?, "Report should be marked as approved"
  end

  # ============================================================
  # SERIALIZATION TESTS
  # ============================================================

  test "should serialize departments as JSON array" do
    report = Report.create!(valid_report_params.merge(
      departments: [ "Building & Safety", "Planning" ]
    ))

    report.reload
    assert_equal [ "Building & Safety", "Planning" ], report.departments
    assert_instance_of Array, report.departments
  end

  test "should serialize issue_categories as JSON array" do
    report = Report.create!(valid_report_params.merge(
      issue_categories: [ "Permits", "Inspections", "Fees" ]
    ))

    report.reload
    assert_equal [ "Permits", "Inspections", "Fees" ], report.issue_categories
    assert_instance_of Array, report.issue_categories
  end
end
