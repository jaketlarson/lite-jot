class AddFriendlyToSupportTickets < ActiveRecord::Migration
  def change
    add_column :support_tickets, :slug, :string, :unique => true
  end
end
