class RenamePhotoUploadedToS3 < ActiveRecord::Migration
  def change
    rename_column :users, :photo_uploaded_to_s3, :photo_uploaded_manually
  end
end
