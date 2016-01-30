class Jot < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :topics
  belongs_to :user

  attr_accessor :is_temp, :temp_key

  validates_presence_of :content
  validates_presence_of :user_id

  default_scope { order("created_at ASC") }
end
