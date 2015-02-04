class AddDefaultValueToIsHighlightedAttribute < ActiveRecord::Migration
  def change
    change_column :jots, :is_highlighted, :boolean, :default => false
  end
end
