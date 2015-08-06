class ChangeSpecificTopicsType < ActiveRecord::Migration
  def change
    change_column :shares, :specific_topics, :text
  end
end
