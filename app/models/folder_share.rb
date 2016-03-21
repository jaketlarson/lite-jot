class FolderShare < ActiveRecord::Base
  # folder_shares exist if any topic within a folder is shared.
  belongs_to :folder
  belongs_to :user, :foreign_key => 'recipient_id'
  acts_as_paranoid

  #serialize :specific_topics

  validates_presence_of :recipient_email

  attr_accessor :specific_topics
  
  default_scope { order("created_at ASC") }

  after_create :send_share_email

  def send_share_email
    if !self.recipient_id.nil? 
      # If the user is registered, and is opted into emails
      recip_user = User.where('id = ?', self.recipient_id).first
      if recip_user.receives_email
        folder_title = Folder.find(self.folder_id).title
        UserNotifier.send_share_with_registered_user_email(recip_user.id, self.sender_id, folder_title).deliver_later
      end
    else
      # If the user is not registered
      folder_title = Folder.find(self.folder_id).title
      UserNotifier.send_share_with_nonregistered_user_email(self.recipient_email, self.sender_id, folder_title).deliver_later
    end
  end
end
