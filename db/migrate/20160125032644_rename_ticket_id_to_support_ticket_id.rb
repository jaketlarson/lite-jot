class RenameTicketIdToSupportTicketId < ActiveRecord::Migration
  def change
    rename_column :support_ticket_messages, :ticket_id, :support_ticket_id
  end
end
