class Vote < ApplicationRecord
  belongs_to :report

  validates :voter_token, presence: true
  validates :voter_token, uniqueness: { scope: :report_id, message: "has already voted on this report" }
  validates :report_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
