class TopicShare < ActiveRecord::Base
  # topic_shares are just nested shares within folder shares, and are created for every share
  # within a folder.
  belongs_to :folder
  belongs_to :user, :foreign_key => 'recipient_id'
  acts_as_paranoid

  validates_presence_of :recipient_email
  
  default_scope { order("created_at ASC") }
end
