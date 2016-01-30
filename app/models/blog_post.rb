class BlogPost < ActiveRecord::Base
  include Bootsy::Container
  extend FriendlyId
  friendly_id :title, :use => :slugged
  self.per_page = 10
  acts_as_paranoid


  validates_presence_of :user_id
  validates_presence_of :title
  validates_presence_of :body

  default_scope { order("created_at DESC") }
end
