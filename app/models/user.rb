class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :issues, foreign_key: :submitted_by_id
  has_many :supports
  has_many :support_comments
  has_many :supported_issues, through: :supports, source: :issue

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
