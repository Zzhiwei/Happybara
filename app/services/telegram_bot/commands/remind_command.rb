module TelegramBot::Commands
  class RemindCommand < Command
    def initialize(bot, message, user)
      super(bot, message, user)
    end

    def execute
      if content.nil?
        @bot.api.send_message(chat_id: chat_id, text: "The /remind commands are:\ncreate [hour]\ndelete [hour]\nlist")
      elsif content.include? ("create")
        _, hour = content.split(" ", 2)
        result = TelegramRemindersService.create_reminder(user_id: user.id, hour: Integer(hour))
        if result.key?(:success)
          @bot.api.send_message(chat_id: chat_id, text: "New reminder created for #{hour}!")
        else
          @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again. #{result.error}")
        end
      elsif content.include? ("delete")
        _, hour = content.split(" ", 2)
        result = TelegramRemindersService.delete_reminder(user_id: user.id, hour: hour)
        if result.key?(:success)
          @bot.api.send_message(chat_id: chat_id, text: "Reminder deleted for #{hour}!")
        else
          @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again. #{result.error}")
        end
      elsif content.include? ("list")
        puts "remind list"
        maxListed = 10
        remindersArray = TelegramRemindersService.get_reminders_for_user_id(user.id)
        responseString = "Here is your list of reminders!\n\n"
        remindersArray.each_with_index do |reminder, i|
          if i < maxListed
            responseString << "#{i+1}: #{reminder}\n"
          end
        end
        if remindersArray.length > maxListed
          responseString << "...\n"
        end
        @bot.api.send_message(chat_id: chat_id, text: responseString)
      else
        @bot.api.send_message(chat_id: chat_id, text: "The /remind commands are:\ncreate [hour]\ndelete [hour]\nlist")
      end
    end

    def chat_id
      message.chat.id
    end
  end
end
