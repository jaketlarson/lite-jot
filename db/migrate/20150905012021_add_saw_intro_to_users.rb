class AddSawIntroToUsers < ActiveRecord::Migration
  def change
    add_column :users, :saw_intro, :boolean, :default => false
  end
end
