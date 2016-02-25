class DropBootsy < ActiveRecord::Migration
  def change
    drop_table :bootsy_image_galleries
    drop_table :bootsy_images
  end
end
