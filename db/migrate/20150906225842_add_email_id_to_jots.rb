class AddEmailIdToJots < ActiveRecord::Migration
  def change
    add_column :jots, :tagged_email_id, :integer
  end
end
