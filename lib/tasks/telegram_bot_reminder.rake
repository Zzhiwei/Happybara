require "telegram/bot"
require "rufus/scheduler"

TOKEN = Rails.application.credentials.dig(:telegram_bot_key)

namespace :daily_reminders do
  desc "Execute daily reminders on Telegram"
  task remind: :environment do
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
        remind_every_hour()
      rescue StandardError => e
        Rails.logger.error "An error occurred: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        restart_bot(RESTART_DELAY)
      end
    end
  end
end

def remind_every_hour
  scheduler = Rufus::Scheduler.new

  # scheduler.cron "0 * * * *" do
  scheduler.every "10s" do
    puts "TELEGRAM_BOT_REMINDER: executing reminders service --->"
    Telegram::Bot::Client.run(TOKEN) do |bot|
      user_ids = TelegramRemindersService.get_user_ids_for_current_hour()
      puts "TELEGRAM_BOT_REMINDER: No of users = #{user_ids.count}"
      user_ids.each do |id|
        puts "    Sending reminder to #{id}"
        bot.api.send_message(chat_id: id, text: "Add your expenses for today!")
      end
    end
  end

  scheduler.join
end
