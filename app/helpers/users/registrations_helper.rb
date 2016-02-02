module Users::RegistrationsHelper
  def user_photo(url)
    if url.empty?
      '/assets/images/photo_placeholder.png'
    else
      url
    end
  end
end
