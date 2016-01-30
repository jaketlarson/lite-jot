class SupportTicketNewByDefault < ActiveRecord::Migration
  def change
    change_column :support_tickets, :status, :string, :default => 'new'
  end
end
