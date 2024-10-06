class TelegramBotService
  def run
    token = Rails.application.credentials.dig(:telegram_bot_key)

    Telegram::Bot::Client.run(token) do |bot|
      @bot = bot
      bot.listen do |message|
        puts "received message #{message}"

        user = User.find_by_id(message.from.id)

        if !user
          if message.text == "/register"
            User.create(id: message.from.id, registration_state: "awaiting_email")
            bot.api.send_message(chat_id: message.chat.id, text: "Please enter your email")
          else
            bot.api.send_message(
              chat_id: message.chat.id, text: "Unregistered. Please use /register to sign up."
            )
          end
          next
        end

        case user.registration_state
        when "registered"
          if message.is_a?(Telegram::Bot::Types::Message)
            if message.edit_date
              handle_edited_flow user, message
            else
              handle_message_flow user, message
            end
          else
            handle_registration user, message
          end
        end
      end
    end
  end

  private
  def handle_message_flow(user, message)
    command, content = message.text.split(" ", 2)

    case command
    when "/start"
      @bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount]!")
    when "/new"
      begin
        expenseData = content.split("-")  # remove /new from string?
      rescue
        @bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount]!")
        return
      end
      if expenseData.length() != 2 or expenseData[1].class.is_a?(Integer)
        @bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
      else
        title = expenseData[0]
        amount = expenseData[1].to_f.round(2)
        expense = Expense.create(user_id: user.id, message_id: message.message_id, title: title, amount: amount, time: Time.now)
        if expense.persisted?
          @bot.api.send_message(chat_id: message.chat.id, text: "Successfully added new expense!")
        else
          @bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
        end
      end
    when "/list"
      expensesArray = Expense.where("user_id LIKE ?", "%#{user.id}%")
      responseString = "Here is your list of expenses!\n\n"
      totalAmount = 0
      expensesArray.each_with_index do |expense, i|
        responseString << "Expense #{i}: #{expense.title} - $#{expense.amount}\n"
        totalAmount += expense.amount
      end
      responseString << "\nTotal amount spent: $#{totalAmount}"
      @bot.api.send_message(chat_id: message.chat.id, text: responseString)
    when "/delete"
      # To be handled. Delete last added transaction?
    end
  end

  private def handle_edited_flow(user, message)
    # Get expense with message id and update amount
    command, content = message.text.split(" ", 2)

    case command
    when "/new"  # for now, only handle editing added transactions
      begin
        expenseData = content.split("-")  # remove /new from string?
      rescue
        @bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount]!")
        return
      end
      if expenseData.length() != 2 or expenseData[1].class.is_a?(Integer)
        @bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
      else
        title = expenseData[0]
        amount = expenseData[1].to_f.round(2)
        oldExpense = Expense.find_by(user_id: user.id, message_id: message.message_id)
        newExpense = oldExpense.update(title: title, amount: amount)
        if newExpense
          @bot.api.send_message(chat_id: message.chat.id, text: "Successfully edited new expense!")
        else
          @bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
        end
      end
    end
  end

  def handle_registration(user, message)
    puts "handling registration"
    case user.registration_state
    when "awaiting_email"
      user.update(email: message.text, registration_state: "awaiting_password")
      @bot.api.send_message(chat_id: message.chat.id, text: "Please enter your password")
    when "awaiting_password"
      user.update(password_hash: message.text, registration_state: "registered")
      @bot.api.send_message(chat_id: message.chat.id, text: "Registration complete!")
    else
      @bot.api.send_message(chat_id: message.chat.id, text: "Unregistered. Please use /register to sign up.")
    end
  end
end

Signal.trap("TERM") do
  puts "Shutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end

Signal.trap("INT") do
  puts "Shutting down bot..."
  Rails.application.config.telegram_bot.stop
  exit
end
