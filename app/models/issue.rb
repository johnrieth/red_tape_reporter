class Issue < ApplicationRecord
  belongs_to :submitted_by, class_name: "User"
  has_many :supports, dependent: :destroy
  has_many :supporters, through: :supports, source: :user

  enum :category, { parking: 0, environmental_review: 1, zoning: 2, permits: 3, other: 4 }
  enum :status, { active: 0, resolved: 1, under_review: 2 }

  validates :title, :description, :submitted_by_id, presence: true

  scope :by_support_count, -> { left_joins(:supports).group(:id).order("COUNT(supports.id) DESC") }
  scope :by_trending, -> { where("created_at > ?", 30.days.ago).by_support_count }
  scope :public_visible, -> { where(is_public: true) }

  def support_count
    supports.count
  end

  def cost_impact_total
    supports.sum(:estimated_cost).to_i
  end

  def projects_affected
    supports.select(:project_reference).where.not(project_reference: nil).distinct.count
  end

  def trend_direction
    recent = supports.where("created_at > ?", 14.days.ago).count
    prior = supports.where("created_at > ? AND created_at <= ?", 28.days.ago, 14.days.ago).count

    return "stable" if recent == prior
    recent > prior ? "rising" : "declining"
  end
end
