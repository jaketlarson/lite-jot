class AddImprovementsToTickets < ActiveRecord::Migration
  def change
    change_column :support_tickets, :status, :string, :default => 'unanswered'
    add_column :support_ticket_messages, :type, :string
  end
end
