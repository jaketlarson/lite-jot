class TopicSerializer < ActiveModel::Serializer
  attributes :id, :title, :folder_id, :user_id, :has_manage_permissions
  delegate :current_user, to: :scope

  def has_manage_permissions
    if object.user_id == scope.id
      return true
    else
      folder = Folder.find(object.folder_id)
      if folder.user_id == scope.id
        return true
      else
        return false
      end
    end
  end
end
