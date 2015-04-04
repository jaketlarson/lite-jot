class AddIsViewingKeyControlsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_viewing_key_controls, :boolean, :default => true
  end
end
