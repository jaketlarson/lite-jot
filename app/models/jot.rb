class Jot < ActiveRecord::Base
  belongs_to :topics
  belongs_to :user

  validates :content, {
    :presence => true
  }

  validates :user_id, {
    :presence => true
  }
end
