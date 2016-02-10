class TopicShare < ActiveRecord::Base
  # topic_shares are just nested shares within folder shares, and are created for every share
  # within a folder.
  belongs_to :folder
  belongs_to :user, :foreign_key => 'recipient_id'
  acts_as_paranoid

  validates_presence_of :recipient_email
  
  default_scope { order("created_at ASC") }

  def self.add_new(fshare, topic, sender)
    tshare = TopicShare.new(
      :recipient_email => fshare.recipient_email,
      :recipient_id => fshare.recipient_id,
      :topic_id => topic.id,
      :folder_id => fshare.folder_id,
      :sender_id => sender.id
    ).save!
  end

  def self.share_new_topic_with_applicable_users(folder_id, topic_id, owner)
    # Shares topic with users with whom the folder was shared with
    # and set FolderShare.is_all_topics to true.
    # When topics are created in this folder, they should be auto-shared.
    fshares = FolderShare.where(
      'folder_id = ? AND sender_id = ? AND is_all_topics = ?',
      folder_id,
      owner.id,
      true
    )

    fshares.each do |fshare|
      topic = Topic.where('id = ?', topic_id).first
      self.add_new(fshare, topic, owner)
    end

  end
end
