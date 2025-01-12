module TelegramBot
  class MessageHandler
    module RegistrationState
      AWAITING_EMAIL = "awaiting_email"
      AWAITING_PASSWORD = "awaiting_password"
      REGISTERED = "registered"
    end

    def initialize(bot, message)
      @bot = bot
      @message = message
    end

    def process
      @user = User.find_by_id(message.from.id)

      begin
        if !user
          handle_new_user
        else
          handle_existing_user
        end
      rescue StandardError => e
        handle_error e
      end
    end

    private

    attr_reader :bot, :message, :user

    def handle_new_user
      user = User.create(id: message.from.id, registration_state: RegistrationState::AWAITING_EMAIL)
      bot.api.send_message(chat_id: message.from.id, text: "Please enter your email.")
    end

    def handle_existing_user
      if user.registration_state == RegistrationState::REGISTERED
        if message.edit_date
          handle_edited_flow
        else
          handle_message_flow
        end
      else
        handle_registration
      end
    end

    def handle_error(error)
      bot.api.send_message(chat_id: message.from.id, text: "Oops, are you sure you've given the right command?")
      puts "🚨 PLEASE FIX! 🚨 Something was wrong: #{error.inspect}\n#{error.backtrace_locations.first}"
    end

    def handle_edited_flow
      # Get expense with message id and update amount
      command, content = message.text.split(" ", 2)

      case command
      when "/new"  # for now, only handle editing added transactions
        begin
          expenseData = content.split("-")  # remove /new from string?
        rescue
          bot.api.send_message(chat_id: message.chat.id, text: "To create a new transaction, type /new [item name]-[item amount]!")
          return
        end
        if expenseData.length() != 2 or expenseData[1].class.is_a?(Integer)
          bot.api.send_message(chat_id: message.chat.id, text: "Please use the format [item name]-[item amount].")
        else
          title = expenseData[0]
          amount = expenseData[1].to_f.round(2)
          oldExpense = Expense.find_by(user_id: user.id, message_id: message.message_id)
          if oldExpense.nil?
            bot.api.send_message(chat_id: message.chat.id, text: "Oops, can't find this expense. Are you sure it exists?")
            return
          end
          newExpense = oldExpense.update(title: title, amount: amount)
          if newExpense
            bot.api.send_message(chat_id: message.chat.id, text: "Successfully edited new expense!")
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
          end
        end
      end
    end

    def handle_message_flow
      command, content = message.text.split(" ", 2)

      case command
      when "/start"
        Commands::StartCommand.new(bot, message, user).execute
      when "/new"
        Commands::NewCommand.new(bot, message, user).execute
      when "/list"
        Commands::ListCommand.new(bot, message, user).execute
      when "/delete"
        Commands::DeleteCommand.new(bot, message, user).execute
      when "/remind"
        Commands::RemindCommand.new(bot, message, user).execute
      when "/tag"
        Commands::TagCommand.new(bot, message, user).execute
      else
        bot.api.send_message(
          chat_id: message.chat.id,
          text: <<~EOF
            Sorry I didn't get that. Make sure you're using one of the pre-defined commands,
            or type /start to see the list of commands.
          EOF
        )
      end
    end

    def handle_registration
      case user.registration_state
      when RegistrationState::AWAITING_EMAIL
        user.update(email: message.text, registration_state: RegistrationState::AWAITING_PASSWORD)
        bot.api.send_message(chat_id: message.chat.id, text: "Please enter your password")
      when RegistrationState::AWAITING_PASSWORD
        user.update(password_hash: message.text, registration_state: RegistrationState::REGISTERED)
        bot.api.send_message(chat_id: message.chat.id, text: "Registration complete!")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Hi! Please create an account by entering your email.")
      end
    end
  end
end
