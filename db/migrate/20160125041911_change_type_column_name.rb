class ChangeTypeColumnName < ActiveRecord::Migration
  def change
    rename_column :support_ticket_messages, :type, :message_type
  end
end
