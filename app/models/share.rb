class Share < ActiveRecord::Base
  belongs_to :folder
  belongs_to :user, :foreign_key => 'recipient_id'

  attr_accessor :recipient_email
  serialize :specific_topics
  
end
