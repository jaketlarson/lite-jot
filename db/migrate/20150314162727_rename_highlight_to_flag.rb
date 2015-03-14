class RenameHighlightToFlag < ActiveRecord::Migration
  def change
    rename_column :jots, :is_highlighted, :is_flagged
  end
end
