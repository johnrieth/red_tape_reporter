class Comment < ApplicationRecord
  belongs_to :report

  validates :content, presence: true, length: { minimum: 3, maximum: 1000 }
  validates :commenter_token, presence: true
  validates :report_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
end
