class Report < ApplicationRecord
    # Associations
    has_many :votes, dependent: :destroy
    has_many :comments, dependent: :destroy

    # Scopes
    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :anonymous, -> { not_deleted.where(anonymous: true) }
    scope :identified, -> { not_deleted.where(anonymous: false) }
    scope :new_reports, -> { not_deleted.where(status: "new") }
    scope :recent, -> { order(created_at: :desc) }
    scope :verified, -> { not_deleted.where.not(verified_at: nil) }
    scope :approved, -> { not_deleted.where.not(approved_at: nil) }
    scope :pending_review, -> { not_deleted.where.not(verified_at: nil).where(approved_at: nil) }
    scope :unverified, -> { not_deleted.where(verified_at: nil) }
    scope :publicly_shared, -> { not_deleted.approved.where(share_publicly: true) }

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

    def approved?
        approved_at.present?
    end

    def deleted?
        deleted_at.present?
    end

    def soft_delete
        update(deleted_at: Time.current)
    end

    def approve
        update(approved_at: Time.current, status: "approved")
    end

    # Find related reports based on shared tags and geography
    def related_reports(limit: 10)
        return Report.none unless share_publicly?

        # For SQLite compatibility, we'll use Ruby to filter by overlapping categories
        # Find reports from same location or with overlapping issue categories
        candidates = Report.publicly_shared
            .where.not(id: id)
            .to_a

        # Score reports by relevance
        scored = candidates.map do |report|
            score = 0
            # Add points for overlapping issue_categories
            score += (report.issue_categories & issue_categories).size * 2
            # Add points for location match
            if report.location.downcase == location.downcase
                score += 3
            elsif report.location.downcase.include?(location.downcase) ||
                  location.downcase.include?(report.location.downcase)
                score += 1
            end
            # Add points for same departments
            score += (report.departments & departments).size
            [ report, score ]
        end

        # Get top scored reports
        related_ids = scored
            .select { |_r, s| s.positive? }
            .sort_by { |_r, s| -s }
            .first(limit)
            .map { |r, _s| r.id }

        Report.where(id: related_ids).order(created_at: :desc)
    end

    # Count of votes for this report
    def vote_count
        votes.count
    end

    # Check if a voter has already voted (by token)
    def voted_by?(voter_token)
        votes.exists?(voter_token: voter_token)
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
