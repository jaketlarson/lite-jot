class Jot < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :topics
  belongs_to :user

  attr_accessor :is_temp, :temp_key, :em_created_at
  # em_created_at is the datetime the user wrote the jot while in airplane mode

  validates_presence_of :content
  validates_presence_of :user_id

  default_scope { order("created_at ASC") }

  def self.generate_checklist_item_id
    16.times.map { [*'0'..'9', *'a'..'z', *'A'..'Z'].sample }.join
  end

  def self.append_id_to_new_checklist(content)
    checklist = JSON.parse(content)
    checklist.each do |item|
      # Using a random ID generator for now..
      # Move this into a separate method. Same for #update (same line)
      rid = self.generate_checklist_item_id
      item['id'] = rid
    end
    return checklist.to_json
  end

  # Creates a jot based off an uploaded item.
  # The content of the jot is just the id to the upload.
  # When it comes time to show the jot, the serializer will use the upload
  # id to get the image path.
  def self.create_jot_from_upload(user_id, upload_id, topic_id)
    topic = Topic.find(topic_id)
    folder = Folder.find(topic.folder_id)

    jot = Jot.create(
      :user_id => user_id,
      :content => {:upload_id => upload_id, :identified_text => ''}.to_json,
      :jot_type => 'upload',
      :topic_id => topic.id,
      :folder_id => folder.id,
      :color => 'default'
    )

    # Updated updated_at for topic and folder
    topic.touch
    folder.touch

    # Now save a reference from upload to jot.
    ap "AND THE JOT ID IS... #{jot.id}"
    upload = Upload.find(upload_id)
    upload.jot_id = jot.id
    upload.save

    return jot
  end


end
