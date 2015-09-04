class UserNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.from_email_address

  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'A warm welcome to Lite Jot, '+@user.display_name+'!' )
  end

  def send_share_with_registered_user_email(recip_user, sender_user, folder_title)
    @recip_user = recip_user
    @sender_user = sender_user
    @folder_title = folder_title
    mail( :to => @recip_user.email,
    :subject => 'A folder has been shared with you' )
  end

  def send_share_with_nonregistered_user_email(recip_email, sender_user, folder_title)
    @recip_email = recip_email
    @sender_user = sender_user
    @folder_title = folder_title
    mail( :to => @recip_email,
    :subject => 'A folder has been shared with you' )
  end
end