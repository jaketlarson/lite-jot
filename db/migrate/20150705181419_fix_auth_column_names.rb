class FixAuthColumnNames < ActiveRecord::Migration
  def change
    rename_column :users, :provider, :auth_provider
    rename_column :users, :provider_uid, :auth_provider_uid
  end
end
