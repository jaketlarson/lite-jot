class AddEmailSubToUsers < ActiveRecord::Migration
  def change
    add_column :users, :receives_email, :boolean, :default => true
  end
end
