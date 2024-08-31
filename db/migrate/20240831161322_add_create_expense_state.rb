class AddCreateExpenseState < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :create_expense_state, :string
  end
end
