class UserSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :display_name,
    :email,
    :errors,
    :notifications_seen,
    :receives_email,
    :saw_intro,
    :preferences,
    :meta
  )
  
  def errors
    error_text = ""
    object.errors.each do |key, errors|
      error_text += "#{User.human_attribute_name(key)} #{errors}<br>"
    end
    
    return error_text
  end

  def preferences
    if object.preferences.nil? then return nil end
    begin
      JSON.parse(object.preferences)
    rescue
      return nil
    end
  end

  def meta
    UserMetaDatumSerializer.new(object.meta, :root => false)
  end

end
