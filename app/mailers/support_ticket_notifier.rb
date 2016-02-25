class SupportTicketNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.support_email_address

  def send_creation_email(ticket_id, user_id)
    @ticket = SupportTicket.find(ticket_id)
    @user = User.find(user_id)
    m = mail( :to => @user.email,
    :subject => "Ticket ##{@ticket.unique_id} - Your Support Ticket has been Created" )
    m.transport_encoding = "base64"
    m
  end

  def send_response_email(ticket_id, user_id)
    @ticket = SupportTicket.find(ticket_id)
    @user = User.find(user_id)
    m = mail( :to => @user.email,
    :subject => "Ticket ##{@ticket.unique_id} - New Response from Support" )
    m.transport_encoding = "base64"
    m
  end

  def send_creation_admin_notification_email(ticket_id, user_id)
    @ticket = SupportTicket.find(ticket_id)
    @user = User.find(user_id)
    m = mail( :to => Rails.application.secrets.from_email_address,
    :subject => "Ticket ##{@ticket.unique_id} - New Support Ticket Created" )
    m.transport_encoding = "base64"
    m
  end

  def send_response_admin_notification_email(ticket_id, user_id)
    @ticket = SupportTicket.find(ticket_id)
    @user = User.find(user_id)
    m = mail( :to => Rails.application.secrets.from_email_address,
    :subject => "Ticket ##{@ticket.unique_id} - New Support Ticket Response" )
    m.transport_encoding = "base64"
    m
  end
end
