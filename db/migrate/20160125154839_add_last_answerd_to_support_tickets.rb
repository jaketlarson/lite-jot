class AddLastAnswerdToSupportTickets < ActiveRecord::Migration
  def change
    add_column :support_tickets, :last_answer_at, :datetime
    add_column :support_tickets, :author_last_read_at, :datetime
  end
end
