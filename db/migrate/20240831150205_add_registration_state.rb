class AddRegistrationState < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :registration_state, :string
  end
end
