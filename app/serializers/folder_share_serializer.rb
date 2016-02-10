class FolderShareSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :folder_id,
    :recipient_id,
    :is_all_topics,
    :specific_topics,
    :sender_id,
    :recipient_email,
    :recipient_display_name,
    :permissions_preview
  )

  def recipient_email
    object.recipient_email
  end

  def recipient_display_name
    if object.recipient_id
      user = User.where('id = ?', object.recipient_id).first
      if user
        user.display_name
      else
        ""
      end
    else
      ""
    end
  end

  def permissions_preview
    tshare_count = TopicShare.where('folder_id = ?', object.folder_id).count
    topic_count = Topic.where('folder_id = ?', object.folder_id).count

    if tshare_count == topic_count
      "sharing all topics"
    else
      if tshare_count > 0
        "sharing specific topics"
      else
        "sharing nothing"
      end
    end
  end

  def specific_topics
    topics = []

    tshares = TopicShare.where('folder_id = ?', object.folder_id)
    tshares.each do |tshare|
      topics.push(tshare.topic_id.to_s)
    end

    topics
  end
end
