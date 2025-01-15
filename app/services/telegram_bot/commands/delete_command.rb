module TelegramBot::Commands
  class DeleteCommand < Command
    def initialize(bot, message, user)
      super(bot, message, user)
    end

    def execute
      lastExpense = Expense.where("user_id LIKE ?", "%#{user.id}%").order(id: :desc).first
      if lastExpense
        lastExpense.destroy
        bot.api.send_message(chat_id: message.chat.id, text: "Last expense deleted: #{lastExpense.title}, $#{lastExpense.amount}")
      end
    end
  end
end
