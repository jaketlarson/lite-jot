class FeedbackNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.support_email_address

  def admin_notification_email(feedback)
    @feedback = feedback
    m = mail( :to => Rails.application.secrets.support_email_address,
    :subject => "Lite Jot Feedback" )
    m.transport_encoding = "base64"
    m
  end

  def sender_confirmation_email(feedback)
    @feedback = feedback
    m = mail( :to => @feedback.email,
    :subject => "Feedback Received" )
    m.transport_encoding = "base64"
    m
  end
end
