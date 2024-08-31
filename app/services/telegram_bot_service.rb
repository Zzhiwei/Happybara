class TelegramBotService
  def run
    token = Rails.application.credentials.dig(:telegram_bot_key)

    Telegram::Bot::Client.run(token) do |bot|
      @bot = bot

      bot.listen do |message|
        user = User.find_or_create_by(id: message.from.id)

        # if user is registering


        # if user has not usered and entered "/register"

        # if user has not reigstered and did not enter /register



        if message == '/register'
          user.update(registration_state: 'awaiting_email')
          bot.api.send_message(chat_id: message.chat.id, text: "Please enter your email")
          next
        end

        # if user is nil registration_state is nil too
        unless user
          bot.api.send_message(
            chat_id: message.chat.id, text: "Unregistered. Please use /register to sign up."
          )
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
    @bot.api.send_message(chat_id: message.chat.id, text: "congrats!")
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

