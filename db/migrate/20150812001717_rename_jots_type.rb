class RenameJotsType < ActiveRecord::Migration
  def change
    rename_column :jots, :type, :jot_type
  end
end
