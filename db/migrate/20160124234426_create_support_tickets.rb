class CreateSupportTickets < ActiveRecord::Migration
  def change
    create_table :support_tickets do |t|
      t.integer :user_id
      t.integer :unique_id
      t.string :subject
      t.string :status

      t.timestamps
    end
  end
end
