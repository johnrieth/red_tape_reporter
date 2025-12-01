class Support < ApplicationRecord
  belongs_to :issue
  belongs_to :user, optional: true
  has_many :support_comments, dependent: :destroy

  enum :visibility, { anonymous: 0, attributed: 1 }

  validates :issue_id, presence: true
  validates :issue_id, uniqueness: { scope: :user_id }, if: -> { user.present? }
end
