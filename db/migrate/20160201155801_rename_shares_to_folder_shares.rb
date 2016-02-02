class RenameSharesToFolderShares < ActiveRecord::Migration
  def change
    rename_table :shares, :folder_shares
  end
end
