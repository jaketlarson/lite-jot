class Topic < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user
  belongs_to :folder
  has_many :jots, :dependent => :destroy

  validates_presence_of :user_id

  default_scope { order("updated_at DESC") }
end
