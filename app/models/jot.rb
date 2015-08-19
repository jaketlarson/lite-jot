class Jot < ActiveRecord::Base
  belongs_to :topics
  belongs_to :user

  attr_accessor :is_temp, :temp_key

  validates :content, {
    :presence => true
  }

  validates :user_id, {
    :presence => true
  }

  default_scope { order("created_at ASC") }
end
