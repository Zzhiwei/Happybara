class TelegramBotService
  def run
    token = Rails.application.credentials.dig(:telegram_bot_key)

    Telegram::Bot::Client.run(token) do |bot|
      @bot = bot
      bot.listen do |message|
        user = User.find_by_id(message.from.id)

        if !user
          if message.text == '/register'
            User.create(id: message.from.id, registration_state: 'awaiting_email')
            bot.api.send_message(chat_id: message.chat.id, text: "Please enter your email")
          else
            bot.api.send_message(
              chat_id: message.chat.id, text: "Unregistered. Please use /register to sign up."
            )
          end
          next
        end

        case user.registration_state
        when 'registered'
          handle_main_flow user, message
        else
          handle_registration user, message
        end

      end
    end
    end

  private
  def handle_main_flow(user, message)
    if user.create_expense_state == 'awaiting_amount'
      amount = message.text.to_f.round(2)
      Expense.create(user_id: user.id, amount: amount, time: Time.now)
      user.update(create_expense_state: nil)
      return
    end

    case message.text
    when '/new'
      expenseData = message.text[5..-1].split("-")  # remove /new from string?
      if expenseData.length() != 2 or expenseData[1].class != INT
        @bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
      else
        title = expenseData[0]
        amount = expenseData[1].to_f.round(2)
        expense = Expense.create(user_id: user.id, title: title, amount: amount, time: Time.now)
        if expense.persisted?
          @bot.api.send_message(chat_id: message.chat.id, text: "Successfully added new expense!")
        else
          @bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
        end
      end
  end

  def handle_registration(user, message)
    case user.registration_state
    when 'awaiting_email'
      user.update(email: message.text, registration_state: 'awaiting_password')
      @bot.api.send_message(chat_id: message.chat.id, text: "Please enter your password")
    when 'awaiting_password'
      user.update(password_hash: message.text, registration_state: 'registered')
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

