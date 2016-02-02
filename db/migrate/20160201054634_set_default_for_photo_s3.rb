class SetDefaultForPhotoS3 < ActiveRecord::Migration
  def change
    change_column :users, :photo_uploaded_to_s3, :boolean, :default => false
  end
end
