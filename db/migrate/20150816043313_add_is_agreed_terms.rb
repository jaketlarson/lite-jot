class AddIsAgreedTerms < ActiveRecord::Migration
  def change
    add_column :users, :is_terms_agreed, :boolean, :default => false
  end
end
