class AddTitleToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :title, :string
  end
end
