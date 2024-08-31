
require 'telegram/bot'

namespace :telegram_bot do
  desc "Start the Telegram bot"
  task bot: :environment do
    TelegramBotService.new.run
  end
end
