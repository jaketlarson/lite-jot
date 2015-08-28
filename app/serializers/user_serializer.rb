class UserSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :email, :errors, :notifications_seen, :receives_email
  
  def errors
    error_text = ""
    object.errors.each do |key, errors|
      error_text += "#{User.human_attribute_name(key)} #{errors}<br>"
    end
    
    return error_text
  end
end
