class MakeIsAllTopicsFalseByDefault < ActiveRecord::Migration
  def change
    change_column :folder_shares, :is_all_topics, :boolean, :default => false
  end
end
