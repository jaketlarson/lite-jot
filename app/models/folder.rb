class Folder < ActiveRecord::Base
  acts_as_paranoid

  has_many :topics, :dependent => :destroy
  has_many :shares, :dependent => :destroy
  
  belongs_to :user

  validates :user_id, {
    :presence => true
  }
end
