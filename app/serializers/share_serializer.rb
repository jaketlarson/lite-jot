class ShareSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :folder_id,
    :recipient_id,
    :is_all_topics,
    :specific_topics,
    :owner_id,
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
    if object.is_all_topics
      "sharing all topics"
    else
      if !object.specific_topics.nil? && object.specific_topics.length > 0
        "sharing specific topics"
      else
        "sharing nothing"
      end
    end
  end
end
