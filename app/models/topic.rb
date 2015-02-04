class Topic < ActiveRecord::Base
  has_many :jots

  validates :user_id, {
    :presence => true
  }
end
