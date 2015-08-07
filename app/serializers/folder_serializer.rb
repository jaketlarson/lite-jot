class FolderSerializer < ActiveModel::Serializer
  attributes :id, :title, :has_manage_permissions
  delegate :current_user, to: :scope

  def has_manage_permissions
    object.user_id == scope.id
  end
end
