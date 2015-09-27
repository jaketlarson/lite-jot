class AddColorToJots < ActiveRecord::Migration
  def change
    add_column :jots, :color, :string
  end
end
