class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.decimal :amount
      t.datetime :time
      t.integer :user_id

      t.timestamps
    end
  end
end
