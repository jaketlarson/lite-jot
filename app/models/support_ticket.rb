class SupportTicket < ActiveRecord::Base
  extend FriendlyId
  friendly_id :unique_id, :use => :slugged

  belongs_to :user
  has_many :support_ticket_messages, :dependent => :destroy

  validates_presence_of :unique_id
  validates_presence_of :subject

  self.per_page = 10

  after_create :send_creation_email, :send_creation_admin_notification_email

  def send_creation_email
    SupportTicketNotifier.send_creation_email(self.id, self.user_id).deliver_later
  end

  def send_response_email
    SupportTicketNotifier.send_response_email(self.id, self.user_id).deliver_later
  end

  def send_creation_admin_notification_email
    SupportTicketNotifier.send_creation_admin_notification_email(self.id, self.user_id).deliver_later
  end

  def send_response_admin_notification_email
    SupportTicketNotifier.send_response_admin_notification_email(self.id, self.user_id).deliver_later
  end

  def change_status(status, user_id)
    if status == 'new'
      self.mark_new
    elsif status == 'answered'
      self.mark_answered(user_id)
    elsif status == 'in_progress'
      self.mark_in_progress
    elsif status == 'requires_more_details'
      self.mark_requires_more_details(user_id)
    end
  end

  def mark_answered(user_id)
    if self.status == 'answered'
      return
    end

    ticket_message = SupportTicketMessage.new(
      :message => '...', # Since it's needed for validation
      :message_type => 'notice_answered',
      :support_ticket_id => self.id,
      :user_id => user_id
    )
    ticket_message.save

    # Update ticket status
    self.status = 'answered'
    self.save
  end

  def mark_new
    self.status = 'new'
    self.save
  end

  def mark_in_progress
    self.status = 'in_progress'
    self.save
  end

  def mark_requires_more_details(user_id)
    if self.status == 'requires_more_details'
      return
    end

    ticket_message = SupportTicketMessage.new(
      :message => '...', # Since it's needed for validation
      :message_type => 'notice_requires_more_details',
      :support_ticket_id => self.id,
      :user_id => user_id
    )
    ticket_message.save

    self.status = 'requires_more_details'
    self.save
  end
end
