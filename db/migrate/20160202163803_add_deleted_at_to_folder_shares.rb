class AddDeletedAtToFolderShares < ActiveRecord::Migration
  def change
    add_column :folder_shares, :deleted_at, :datetime
    add_index :folder_shares, :deleted_at
  end
end
