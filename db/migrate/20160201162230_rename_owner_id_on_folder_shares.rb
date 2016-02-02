class RenameOwnerIdOnFolderShares < ActiveRecord::Migration
  def change
    rename_column :folder_shares, :owner_id, :sender_id
  end
end
