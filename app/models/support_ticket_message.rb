class SupportTicketMessage < ActiveRecord::Base
  belongs_to :support_ticket, :foreign_key => "support_ticket_id"

  #attr_accessor :message_type

  validates_presence_of :message

  def self.belongs_to_user?(ticket_id, user_id)
    ticket = SupportTicket.where('id = ? AND user_id = ?', ticket_id, user_id)
    !ticket.empty?
  end
  
  default_scope { order("created_at ASC") }
end
