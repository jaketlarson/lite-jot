class Folder < ActiveRecord::Base
  has_many :topics

  validates :user_id, {
    :presence => true
  }
end
