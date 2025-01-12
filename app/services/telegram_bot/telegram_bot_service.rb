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
        @bot = bot
        bot.listen do |message|
          puts " 📩 Message Received: #{message}"

          user = User.find_by_id(message.from.id)

          begin
            if !user
              user = User.create(id: message.from.id, registration_state: RegistrationState::AWAITING_EMAIL)
              @bot.api.send_message(chat_id: message.from.id, text: "Please enter your email.")
            else
              case user.registration_state
              when RegistrationState::REGISTERED
                if message.edit_date
                  handle_edited_flow user, message
                else
                  handle_message_flow user, message
                end
              else
                handle_registration user, message
              end
            end
          rescue Exception => e
            @bot.api.send_message(chat_id: message.from.id, text: "Oops, are you sure you've given the right command?")
            puts "🚨 PLEASE FIX! 🚨 Something was wrong: #{e.inspect}\n#{e.backtrace_locations.first()}"
          end
        end
      end
    end

    private

    def handle_message_flow(user, message)
      command, content = message.text.split(" ", 2)

      case command
      when "/start"
        Commands::StartCommand.new(@bot, message, user).execute
      when "/new"
        Commands::NewCommand.new(@bot, message, user).execute
      when "/list"
        Commands::ListCommand.new(@bot, message, user).execute
      when "/delete"
        Commands::DeleteCommand.new(@bot, message, user).execute
      when "/remind"
        Commands::RemindCommand.new(@bot, message, user).execute
      when "/tag"
        handle_tag_commands(user, message.chat.id, content)
      else
        handle_unknown_command(message.chat.id)
      end
    end

    def handle_tag_commands(user, chat_id, content)
      user_id = user.id
      if content.nil?
        @bot.api.send_message(chat_id: chat_id, text: "The /tag commands are:\ncreate [name]\ndelete [name]\nlist\nrename [old name]->[new name]\n\nIt is recommended to create tags without spaces for clarity.")
      elsif content.include? ("create")
        _, name = content.split(" ", 2)
        tag = user.tags.create(name: name.strip)
        if tag.persisted?
          @bot.api.send_message(chat_id: chat_id, text: "New tag #{name} created!")
        else
          @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again.")  # refactor this!
          # TODO: tag names must be unique
        end
      elsif content.include? ("delete")
        _, name = content.split(" ", 2)
        tag = Tag.find_by(user: user_id, name: name)
        if tag
          tag.destroy
          @bot.api.send_message(chat_id: chat_id, text: "Tag #{name} deleted!")
        else
          @bot.api.send_message(chat_id: chat_id, text: "Couldn't find tag #{name}")
        end
      elsif content.include? ("list")
        tags = Tag.where(user: user_id).pluck(:name)
        @bot.api.send_message(chat_id: chat_id, text: "Your tags are: #{tags}")
      elsif content.include?("rename") && content.include?("->")
        old, newName = content.split(" ", 2)[1].split("->", 2)
        tagFromUser = user.tags.where(name: old)
        updatedTag = tagFromUser.update(name: newName)
        puts "Tag is #{tag}, tagFromUser is #{tagFromUser}, Updated tag is #{updatedTag}"
        if updatedTag
          @bot.api.send_message(chat_id: chat_id, text: "Tag was renamed from '#{old}' to '#{newName}'!")
        else
          @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again.")
        end
      else
        @bot.api.send_message(chat_id: chat_id, text: "The /tag commands are:\ncreate [name]\ndelete [name]\nlist\nrename [old name]->[new name`]")
      end
    end

    def handle_edited_flow(user, message)
      # Get expense with message id and update amount
      command, content = message.text.split(" ", 2)

      case command
      when "/new"  # for now, only handle editing added transactions
        begin
          expenseData = content.split("-")  # remove /new from string?
        rescue
          @bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount]!")
          return
        end
        if expenseData.length() != 2 or expenseData[1].class.is_a?(Integer)
          @bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
        else
          title = expenseData[0]
          amount = expenseData[1].to_f.round(2)
          oldExpense = Expense.find_by(user_id: user.id, message_id: message.message_id)
          if oldExpense.nil?
            @bot.api.send_message(chat_id: message.chat.id, text: "Oops, can't find this expense. Are you sure it exists?")
            return
          end
          newExpense = oldExpense.update(title: title, amount: amount)
          if newExpense
            @bot.api.send_message(chat_id: message.chat.id, text: "Successfully edited new expense!")
          else
            @bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
          end
        end
      end
    end

    def handle_registration(user, message)
      case user.registration_state
      when RegistrationState::AWAITING_EMAIL
        user.update(email: message.text, registration_state: RegistrationState::AWAITING_PASSWORD)
        @bot.api.send_message(chat_id: message.chat.id, text: "Please enter your password")
      when RegistrationState::AWAITING_PASSWORD
        user.update(password_hash: message.text, registration_state: RegistrationState::REGISTERED)
        @bot.api.send_message(chat_id: message.chat.id, text: "Registration complete!")
      else
        @bot.api.send_message(chat_id: message.chat.id, text: "Hi! Please create an account by entering your email.")
      end
    end

    def handle_unknown_command(chat_id)
      @bot.api.send_message(chat_id: chat_id, text: "Sorry I didn't get that. Make sure you're using one of the pre-defined commands, or type /start to see the list of commands.")
    end

    module RegistrationState
      AWAITING_EMAIL = "awaiting_email"
      AWAITING_PASSWORD = "awaiting_password"
      REGISTERED = "registered"
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
