class RenameLastAnsweredAtInSupportTickets < ActiveRecord::Migration
  def change
    rename_column :support_tickets, :last_answer_at, :last_answered_at
  end
end
