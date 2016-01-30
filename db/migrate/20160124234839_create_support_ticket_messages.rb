class CreateSupportTicketMessages < ActiveRecord::Migration
  def change
    create_table :support_ticket_messages do |t|
      t.integer :ticket_id
      t.integer :user_id
      t.text :message

      t.timestamps
    end
  end
end
