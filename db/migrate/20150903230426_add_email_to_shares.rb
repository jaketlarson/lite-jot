class AddEmailToShares < ActiveRecord::Migration
  def change
    add_column :shares, :recipient_email, :string
  end
end
