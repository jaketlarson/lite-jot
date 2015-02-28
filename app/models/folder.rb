class Folder < ActiveRecord::Base
  has_many :topics, :dependent => :destroy

  validates :user_id, {
    :presence => true
  }
end
