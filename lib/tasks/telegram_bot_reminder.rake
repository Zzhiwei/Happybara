require "net/http"
require "json"


namespace :reminders do
  desc "Execute daily reminders on Telegram"
  task send: :environment do
    sendReminders
  end
end

def sendReminders
  user_ids = TelegramRemindersService.get_user_ids_for_current_hour
  puts "user_ids: #{user_ids}"
  message = "here's your reminder to add your expenses!"
  for id in user_ids
    data = { chat_id: id, text: message }.to_json
    url = URI.parse("https://api.telegram.org/bot#{TOKEN}/sendMessage")
    response = Net::HTTP.post(url, data, { "Content-Type" => "application/json" })
    puts JSON.parse(response.body)
  end
end
