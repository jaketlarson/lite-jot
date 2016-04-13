class AddJotIdToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :jot_id, :integer
  end
end
