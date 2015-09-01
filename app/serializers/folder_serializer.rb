class FolderSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :title,
    :has_manage_permissions,
    :share_id,
    :owner_email,
    :owner_display_name,
    :updated_at_unix
  )
  
  delegate :current_user, to: :scope

  def has_manage_permissions
    object.user_id == scope.id
  end

  def share_id
    if object.user_id == scope.id
      return nil
    else
      share = Share.where('recipient_id = ? AND folder_id = ?', scope.id, object.id).first
      if share
        return share.id
      else
        return nil
      end
    end
  end

  def owner_email
    if object.user_id == scope.id
      scope.email
    else
      User.find(object.user_id).email
    end
  end

  def owner_display_name
    if object.user_id == scope.id
      scope.display_name
    else
      User.find(object.user_id).display_name
    end
  end

  def updated_at_unix
    if object.user_id == scope.id
      return object.updated_at.to_f
    else
      # This folder is shared with this user,
      # and since the updated_at_unix determines order
      # of the folders on screen, updated topics that the
      # user lacks permission to will cause the folder to
      # jump to the top, for no apparent reason.
      # To fix this bug, find the last updated topic the
      # user has access to, and return that unix stamp.
      # This is only necessary if specific topics are set.
      # Otherwise, if the entire folder is visible,
      # this workaround is unnecessary.
      share = Share.where('recipient_id = ? AND folder_id = ?', scope.id, object.id).first
      if share.is_all_topics
        return object.updated_at.to_f
      else
        most_recent_topic = nil
        topics = share.specific_topics
        topics.each do |topic_id|
          topic = Topic.find(topic_id)
          if most_recent_topic.nil?
            most_recent_topic = topic
          elsif most_recent_topic.updated_at.to_f < topic.updated_at.to_f
            most_recent_topic = topic
          end
        end
        return most_recent_topic.updated_at.to_f
      end
    end
  end
end
