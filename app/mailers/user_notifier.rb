class UserNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.from_email_address

  def send_signup_email(user)
    @user = user
    m = mail( :to => @user.email,
    :subject => 'A warm welcome to Lite Jot, '+@user.display_name+'!' )
    m.transport_encoding = "base64"
    m
  end

  def send_share_with_registered_user_email(recip_user, sender_user, folder_title)
    @recip_user = recip_user
    @sender_user = sender_user
    @folder_title = folder_title
    m = mail( :to => @recip_user.email,
    :subject => 'A folder has been shared with you' )
    m.transport_encoding = "base64"
    m
  end

  def send_share_with_nonregistered_user_email(recip_email, sender_user, folder_title)
    @recip_email = recip_email
    @sender_user = sender_user
    @folder_title = folder_title
    m = mail( :to => @recip_email,
    :subject => 'A folder has been shared with you' )
    m.transport_encoding = "base64"
    m
  end

  def send_reset_password_email(user, token)
    @user = user
    @token = token
    m = mail( :to => @user.email,
    :from => Rails.application.secrets.support_email_address,
    :subject => 'Here are your password reset instructions, '+@user.display_name+'!' )
    m.transport_encoding = "base64"
    m.headers['X-MC-Track'] = "False, False"
    m
  end
end
