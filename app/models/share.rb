class Share < ActiveRecord::Base
  belongs_to :folder, :foreign_key => 'folder_id'
  belongs_to :user, :foreign_key => 'recipient_id'

  attr_accessor :recipient_email
  serialize :specific_topics
  
end
