class Jot < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :topics
  belongs_to :user

  attr_accessor :is_temp, :temp_key, :em_created_at
  # em_created_at is the datetime the user wrote the jot while in airplane mode

  validates_presence_of :content
  validates_presence_of :user_id

  default_scope { order("created_at ASC") }
end
