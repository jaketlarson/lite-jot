class UserNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.from_email_address

  # send a signup email to the user, pass in the user object that   contains the user's email address
  def send_signup_email(user)
    @user = user
    mail( :to => @user.email,
    :subject => 'A warm welcome to Lite Jot, '+@user.display_name+'!' )
  end
end
