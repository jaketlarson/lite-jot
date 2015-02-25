class Jot < ActiveRecord::Base
  belongs_to :topics, :foreign_key => 'topic_id'
  validates :content, {
    :presence => true
  }

  validates :user_id, {
    :presence => true
  }
end
