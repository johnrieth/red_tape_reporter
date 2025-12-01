class SupportComment < ApplicationRecord
  belongs_to :support
  belongs_to :user, optional: true

  enum :visibility, { anonymous: 0, attributed: 1 }

  validates :content, :support_id, presence: true
end
