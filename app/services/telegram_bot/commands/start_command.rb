module TelegramBot::Commands
  class StartCommand < Command
    def initialize(bot, message, user)
      super(bot, message, user)
    end

    def execute
      bot.api.send_message(
        chat_id: message.chat.id,
        text: start_message
      )
    end

    private

    def start_message
      <<~EOF
        /new [item name]-[item amount]
        /list
        /delete
        /remind [remind command]
        /tag [tag command]
      EOF
    end
  end
end