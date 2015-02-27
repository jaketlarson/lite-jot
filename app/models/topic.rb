class Topic < ActiveRecord::Base
  belongs_to :user
  has_many :jots, :dependent => :destroy

  validates :user_id, {
    :presence => true
  }
end
