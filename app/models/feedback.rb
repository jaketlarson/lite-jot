class Feedback < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :message

  def send_admin_notification_email
    FeedbackNotifier.admin_notification_email(self).deliver
  end

  def send_confirmation_email
    FeedbackNotifier.sender_confirmation_email(self).deliver
  end
end
