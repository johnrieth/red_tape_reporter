class AuditLog < ApplicationRecord
  belongs_to :report
  belongs_to :user

  # Action types enum
  # Using prefix to avoid conflicts with ActiveRecord methods (delete, etc.)
  enum :action_type, {
    report_approved: 0,
    report_deleted: 1,
    report_exported: 2
  }, prefix: :action, validate: true

  # Serialize metadata as JSON
  serialize :metadata, coder: JSON

  # Validations
  validates :action_type, presence: true
  validates :report_id, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_report, ->(report_id) { where(report_id: report_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action_type) { where(action_type: action_type) }

  # Factory method to create audit log with context
  def self.log_action(report:, user:, action_type:, ip_address: nil, metadata: {})
    create!(
      report: report,
      user: user,
      action_type: action_type,
      ip_address: ip_address,
      metadata: metadata
    )
  end
end
