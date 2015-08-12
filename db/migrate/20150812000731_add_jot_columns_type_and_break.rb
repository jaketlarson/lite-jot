class AddJotColumnsTypeAndBreak < ActiveRecord::Migration
  def change
    add_column :jots, :break_from_top, :boolean, :default => false
    add_column :jots, :type, :string, :default => 'standard'
  end
end
