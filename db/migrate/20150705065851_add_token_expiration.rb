class AddTokenExpiration < ActiveRecord::Migration
  def change
    add_column :users, :token_expiration, :datetime
  end
end
