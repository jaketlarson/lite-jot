class AddPermanentlyDeletedCols < ActiveRecord::Migration
  def change
    add_column :folders, :perm_deleted, :boolean, :default => false
    add_column :topics, :perm_deleted, :boolean, :default => false
    add_column :jots, :perm_deleted, :boolean, :default => false
  end
end
