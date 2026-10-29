class SearchAgentMessage < ApplicationRecord
  validates :role, inclusion: { in: %w[user agent] }
  validates :content, presence: true
end
