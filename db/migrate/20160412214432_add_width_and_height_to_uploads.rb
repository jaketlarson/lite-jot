class AddWidthAndHeightToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :width, :integer, :default => 0
    add_column :uploads, :height, :integer, :default => 0
  end
end
