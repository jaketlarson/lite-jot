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

  def content
    if object.jot_type == 'upload'
      # The jot object's content is the upload id. Grab the url from the upload:
      upload = Upload.where('id = ?', object.content)

      if upload.empty?
        return { :thumbnail => "", :original => "" }.to_json
      else
        return { :thumbnail => upload.first.thumbnail_url, :original => upload.first.original_url }.to_json
      end

    else
      return object.content
    end
  end

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
