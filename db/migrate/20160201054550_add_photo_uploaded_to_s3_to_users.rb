class AddPhotoUploadedToS3ToUsers < ActiveRecord::Migration
  def change
    add_column :users, :photo_uploaded_to_s3, :boolean
  end
end
