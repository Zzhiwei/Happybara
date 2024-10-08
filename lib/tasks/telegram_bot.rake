require 'telegram/bot'

namespace :telegram_bot do
  desc "Start the Telegram bot"
  task bot: :environment do
    RESTART_DELAY = 2
    def restart_bot(delay)
      Rails.logger.info "Restarting bot in #{delay} seconds..."
      delay.downto(1) do |i|
        Rails.logger.info i
        sleep 1
      end
      Rails.logger.info "Restarting..."
    end

    loop do
      begin
        TelegramBotService.new.run
      rescue StandardError => e
        Rails.logger.error "An error occurred: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        restart_bot(RESTART_DELAY)
      end
    end
  end
end
