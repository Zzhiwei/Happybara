module TelegramBot
  class TelegramBotService
    def run
      Rails.logger.info <<~MESSAGE

      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
      ┃                                               ┃
      ┃          🚀 Telegram Bot Started! 🚀          ┃
      ┃                                               ┃
      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
      MESSAGE
      token = Rails.application.credentials.dig(:telegram_bot_key)

      Telegram::Bot::Client.run(token) do |bot|
        bot.listen do |message|
          puts " 📩 Message Received: #{message}"
          MessageHandler.new(bot, message).process
        end
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
end
