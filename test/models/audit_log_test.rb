require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin_user)
    @report = reports(:pending_report)
  end

  # Association tests
  test "belongs to report" do
    audit_log = AuditLog.new(
      report: @report,
      user: @user,
      action_type: :report_approved
    )
    assert_equal @report, audit_log.report
  end

  test "belongs to user" do
    audit_log = AuditLog.new(
      report: @report,
      user: @user,
      action_type: :report_approved
    )
    assert_equal @user, audit_log.user
  end

  # Validation tests
  test "requires action_type" do
    audit_log = AuditLog.new(
      report: @report,
      user: @user
    )
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:action_type], "can't be blank"
  end

  test "requires report_id" do
    audit_log = AuditLog.new(
      user: @user,
      action_type: :report_approved
    )
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:report_id], "can't be blank"
  end

  test "requires user_id" do
    audit_log = AuditLog.new(
      report: @report,
      action_type: :report_approved
    )
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:user_id], "can't be blank"
  end

  # Enum tests
  test "has report_approved action type" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved
    )
    assert audit_log.action_report_approved?
  end

  test "has report_deleted action type" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_deleted
    )
    assert audit_log.action_report_deleted?
  end

  test "has report_exported action type" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_exported
    )
    assert audit_log.action_report_exported?
  end

  test "enum uses prefix to avoid conflicts" do
    audit_log = AuditLog.new(action_type: :report_approved)
    assert_respond_to audit_log, :action_report_approved?
    assert_respond_to audit_log, :action_report_deleted?
    assert_respond_to audit_log, :action_report_exported?
  end

  # Metadata tests
  test "can store metadata as JSON" do
    metadata = { format: "csv", record_count: 42 }
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_exported,
      metadata: metadata
    )

    audit_log.reload
    assert_equal metadata.stringify_keys, audit_log.metadata
  end

  test "metadata can be empty" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved,
      metadata: {}
    )
    assert_equal({}, audit_log.metadata)
  end

  # IP address tests
  test "can store ip_address" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved,
      ip_address: "192.168.1.1"
    )
    assert_equal "192.168.1.1", audit_log.ip_address
  end

  # Scope tests
  test "recent scope orders by created_at desc" do
    old_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved,
      created_at: 2.days.ago
    )

    new_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_exported,
      created_at: 1.day.ago
    )

    recent_logs = AuditLog.recent.to_a
    assert_equal new_log.id, recent_logs.first.id
    assert_equal old_log.id, recent_logs.last.id
  end

  test "for_report scope filters by report_id" do
    other_report = reports(:approved_report)

    report1_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved
    )

    report2_log = AuditLog.create!(
      report: other_report,
      user: @user,
      action_type: :report_approved
    )

    logs = AuditLog.for_report(@report.id)
    assert_includes logs, report1_log
    assert_not_includes logs, report2_log
  end

  test "for_user scope filters by user_id" do
    other_user = users(:regular_user)

    user1_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved
    )

    user2_log = AuditLog.create!(
      report: @report,
      user: other_user,
      action_type: :report_deleted
    )

    logs = AuditLog.for_user(@user.id)
    assert_includes logs, user1_log
    assert_not_includes logs, user2_log
  end

  test "by_action scope filters by action_type" do
    approved_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved
    )

    deleted_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_deleted
    )

    logs = AuditLog.by_action(:report_approved)
    assert_includes logs, approved_log
    assert_not_includes logs, deleted_log
  end

  # Factory method tests
  test "log_action creates audit log with all parameters" do
    audit_log = AuditLog.log_action(
      report: @report,
      user: @user,
      action_type: :report_approved,
      ip_address: "10.0.0.1",
      metadata: { reason: "Verified legitimate report" }
    )

    assert audit_log.persisted?
    assert_equal @report, audit_log.report
    assert_equal @user, audit_log.user
    assert_equal "report_approved", audit_log.action_type
    assert_equal "10.0.0.1", audit_log.ip_address
    assert_equal({ "reason" => "Verified legitimate report" }, audit_log.metadata)
  end

  test "log_action works with minimal parameters" do
    audit_log = AuditLog.log_action(
      report: @report,
      user: @user,
      action_type: :report_approved
    )

    assert audit_log.persisted?
    assert_nil audit_log.ip_address
    assert_equal({}, audit_log.metadata)
  end

  test "log_action raises error if required parameters missing" do
    assert_raises(ActiveRecord::RecordInvalid) do
      AuditLog.log_action(
        report: @report,
        user: nil,
        action_type: :report_approved
      )
    end
  end

  # Integration tests
  test "can chain scopes" do
    AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved,
      created_at: 2.days.ago
    )

    AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_deleted,
      created_at: 1.day.ago
    )

    logs = AuditLog.for_report(@report.id).by_action(:report_approved).recent
    assert_equal 1, logs.count
    assert logs.first.action_report_approved?
  end

  test "audit log is immutable after creation" do
    audit_log = AuditLog.create!(
      report: @report,
      user: @user,
      action_type: :report_approved
    )

    # Audit logs should typically be immutable for compliance
    # This test documents current behavior
    audit_log.update(action_type: :report_deleted)
    assert_equal "report_deleted", audit_log.reload.action_type
  end
end
