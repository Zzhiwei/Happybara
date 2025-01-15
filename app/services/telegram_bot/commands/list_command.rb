module TelegramBot::Commands
  class ListCommand < Command
    def initialize(bot, message, user)
      super(bot, message, user)
    end
  
    def execute
      maxListed = 10
      expensesArray = Expense.where("user_id LIKE ?", "%#{user.id}%").order(id: :desc)
      responseString = "Here is your list of expenses!\n\n"
      totalAmount = 0
      expensesArray.each_with_index do |expense, i|
        if i < maxListed
          expenseString = "#{i+1}: #{expense.title} - $#{expense.amount}"
          expense.tags.each do |tag|
            expenseString << " ##{tag.name}"
          end
          responseString << expenseString + "\n"
        end
        totalAmount += expense.amount
      end
      if expensesArray.length > maxListed
        responseString << "...\n"
      end
      responseString << "\nTotal amount spent: $#{totalAmount}"
      bot.api.send_message(chat_id: message.chat.id, text: responseString)
    end

  end
end
