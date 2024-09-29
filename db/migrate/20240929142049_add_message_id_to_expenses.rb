class AddMessageIdToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column expenses:, :message_id, :string
  end
end
