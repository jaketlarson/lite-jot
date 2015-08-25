class FolderSerializer < ActiveModel::Serializer
  attributes :id, :title, :has_manage_permissions, :share_id, :owner_email, :owner_display_name
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
end
