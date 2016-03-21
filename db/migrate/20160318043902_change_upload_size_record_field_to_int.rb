class ChangeUploadSizeRecordFieldToInt < ActiveRecord::Migration
  def change
    change_column :user_meta_data, :upload_size_this_month, :int, :default => 0
  end
end
