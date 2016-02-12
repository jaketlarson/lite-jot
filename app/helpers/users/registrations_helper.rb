module Users::RegistrationsHelper
  def user_photo(url)
    if url.nil? || url.empty?
      '/assets/images/photo_placeholder.png'
    else
      url
    end
  end

  def user_display_name_by_id(id)
    user = User.where('id = ?', id).first
    if user.nil?
      "Unknown User"
    else
      user.display_name
    end
  end
end
