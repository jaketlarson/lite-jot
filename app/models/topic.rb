class Topic < ActiveRecord::Base
  belongs_to :user
  belongs_to :folder
  has_many :jots, :dependent => :destroy

  validates :user_id, {
    :presence => true
  }

  default_scope { order("updated_at DESC") }
end
