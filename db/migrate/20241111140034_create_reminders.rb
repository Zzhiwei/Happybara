class CreateReminders < ActiveRecord::Migration[7.2]
  def change
    if table_exists?(:reminders)
      drop_table :reminders
    end

    create_table :reminders do |t|
      t.string :user
      t.integer :hour

      t.timestamps
    end

    add_check_constraint :reminders, 'hour >= 0 AND hour <= 23', name: 'check_hour_range'
  end
end
