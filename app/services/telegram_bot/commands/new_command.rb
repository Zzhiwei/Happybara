module TelegramBot
  module Commands
    class NewCommand < Command
      def initialize(bot, message, user)
        super(bot, message, user)
      end

      def execute
        # TODO: fix new item without tags crashing
        # TODO: refactor to make it more readable
        begin
          # format: item name -[Amount] #tags,separated,by,commas
          expenseData, tagNames = content.split("#", 2)  # remove /new from string?
          expenseData = expenseData.strip.split("-")
          tagNames = tagNames.split(",")
        rescue Exception => e
          puts "#{e.inspect}\n#{e.backtrace_locations.first()}"
          bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount] #tags,separated,by,commas!")
          return
        end

        if expenseData.length() != 2 or expenseData[1].class.is_a?(Integer)
          bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
        else
          title = expenseData[0]
          amount = expenseData[1].to_f.round(2)
          expense = Expense.create(user_id: user.id, message_id: message.message_id, title: title, amount: amount, time: Time.now)
          if expense.persisted?
            # definitely refactor this; add tags to expense
            tagNames.each do |name|
              name = name.strip
              if user.tags.exists?(name: name)
                expense.tags << user.tags.where(name: name)
              end
            end
            bot.api.send_message(chat_id: message.chat.id, text: "Successfully added new expense!")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
          end
        end
      end
    end
  end
end
