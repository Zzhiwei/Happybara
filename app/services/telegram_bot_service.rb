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
      user.update(create_expense_state: 'awaiting_amount')
      @bot.api.send_message(chat_id: message.chat.id, text: "Please enter the amount")
    else
      @bot.api.send_message(chat_id: message.chat.id, text: "Use /new to log expense!")
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

