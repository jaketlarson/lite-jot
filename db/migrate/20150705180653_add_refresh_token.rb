class AddRefreshToken < ActiveRecord::Migration
  def change
    add_column :users, :auth_refresh_token, :string
    rename_column :users, :google_token, :auth_token
    rename_column :users, :token_expiration, :auth_token_expiration
  end
end
