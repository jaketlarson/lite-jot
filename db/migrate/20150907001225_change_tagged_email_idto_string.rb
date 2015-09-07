class ChangeTaggedEmailIdtoString < ActiveRecord::Migration
  def change
    change_column :jots, :tagged_email_id, :string
  end
end
