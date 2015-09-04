class Share < ActiveRecord::Base
  belongs_to :folder
  belongs_to :user, :foreign_key => 'recipient_id'

  serialize :specific_topics

  validates_presence_of :recipient_email
  
  default_scope { order("created_at ASC") }

  after_create :send_share_email

  def send_share_email
    if !self.recipient_id.nil? 
      # If the user is registered, and is opted into emails
      recip_user = User.where('id = ?', self.recipient_id).first
      if recip_user.receives_email
        sender_user = User.find(self.owner_id)
        folder_title = Folder.find(self.folder_id).title
        UserNotifier.send_share_with_registered_user_email(recip_user, sender_user, folder_title).deliver
      end
    else
      # If the user is not registered
      sender_user = User.find(self.owner_id)
      folder_title = Folder.find(self.folder_id).title
      UserNotifier.send_share_with_nonregistered_user_email(self.recipient_email, sender_user, folder_title).deliver
    end
  end
end
