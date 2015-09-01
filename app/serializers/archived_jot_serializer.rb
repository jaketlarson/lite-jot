class ArchivedJotSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :content,
    :jot_type,
    :folder_title,
    :topic_title,
    :deleted_at,
    :deleted_at_unix
  )

  delegate :current_user, to: :scope

  def folder_title
    folder = Folder.with_deleted.where("id = ?", object.folder_id)[0]
    folder.title
  end

  def topic_title
    topic = Topic.with_deleted.where("id = ?", object.topic_id)[0]
    topic.title
  end

  def deleted_at
    return nil if object.deleted_at.nil? else I18n.l(object.deleted_at)
  end

  def deleted_at_unix
    return nil if object.deleted_at.nil? else object.deleted_at.to_f
  end
end
