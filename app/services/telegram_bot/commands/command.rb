module TelegramBot::Commands
  class Command
    def initialize(bot, message, user)
      @user = user
      @bot = bot
      @message = message
    end
    
    def execute
      raise NotImplementedError, "Subclasses must implement the execute method"
    end

    private

    attr_reader :user, :message, :bot

    def content
      @content ||= message.text.split(" ", 2)[1]
    end
  end
end
