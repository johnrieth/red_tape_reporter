class Report < ApplicationRecord
    # Scopes
    scope :anonymous, -> { where(anonymous: true) }
    scope :identified, -> { where(anonymous: false) }
    scope :new_reports, -> { where(status: "new") }
    scope :recent, -> { order(created_at: :desc) }

    # Choices used by form selects and checkboxes in the views.
    # These are application-level lists; change as needed.
    PROJECT_TYPES = [
        "Accessory dwelling unit (ADU)",
        "New construction",
        "Renovation / Remodel",
        "Change of use",
        "Other"
    ].freeze

    ISSUE_CATEGORIES = [
        "Permits",
        "Inspections",
        "Zoning",
        "Fees",
        "Plan review",
        "Other"
    ].freeze

    DEPARTMENTS = [
        "Building & Safety",
        "Planning",
        "Water & Power",
        "Bureau of Engineering",
        "Housing Authority",
        "Housing Department",
        "Fire Department",
        "Sanitation Bureau",
        "Other"
    ].freeze

    TIMELINE_IMPACTS = [
        "Less than 3 months",
        "3-6 months",
        "6-12 months",
        "More than 12 months"
    ].freeze

    serialize :departments, type: Array, coder: JSON
    serialize :issue_categories, type: Array, coder: JSON

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :project_type, presence: true
    validates :project_description, presence: true, length: { minimum: 10 }
    validates :location, presence: true
    validates :issue_description, presence: true, length: { minimum: 20 }

    before_create :generate_verification_token
    after_initialize :set_defaults

    def verified?
        verified_at.present?
    end

    private

    def set_defaults
        return unless new_record?
        self.status ||= "new"
        self.departments ||= []
        self.issue_categories ||= []
    end

    def generate_verification_token
        self.verification_token = SecureRandom.urlsafe_base64(32)
    end
end
