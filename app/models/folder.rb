class Folder < ActiveRecord::Base
  has_many :topics, :dependent => :destroy
  has_many :shares, :dependent => :destroy
  
  belongs_to :user

  validates :user_id, {
    :presence => true
  }
end
