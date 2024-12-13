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
          puts "🚨 PLEASE FIX! 🚨 Something was wrong: #{e.message}"
        end
      end
    end
  end

  private
  def handle_message_flow(user, message)
    command, content = message.text.split(" ", 2)

    case command
    when "/start"
      @bot.api.send_message(chat_id: message.chat.id, text: "/new [item name]-[item amount]\n/list\n/delete\n/remind [remind command]")
    when "/new"
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
        expense = Expense.create(user_id: user.id, message_id: message.message_id, title: title, amount: amount, time: Time.now)
        if expense.persisted?
          @bot.api.send_message(chat_id: message.chat.id, text: "Successfully added new expense!")
        else
          @bot.api.send_message(chat_id: message.chat.id, text: "Oops, please try again.")
        end
      end
    when "/list"
      maxListed = 10
      expensesArray = Expense.where("user_id LIKE ?", "%#{user.id}%").order(id: :desc)
      responseString = "Here is your list of expenses!\n\n"
      totalAmount = 0
      expensesArray.each_with_index do |expense, i|
        if i < maxListed
          responseString << "#{i+1}: #{expense.title} - $#{expense.amount}\n"
        end
        totalAmount += expense.amount
      end
      if expensesArray.length > maxListed
        responseString << "...\n"
      end
      responseString << "\nTotal amount spent: $#{totalAmount}"
      @bot.api.send_message(chat_id: message.chat.id, text: responseString)
    when "/delete"
      lastExpense = Expense.where("user_id LIKE ?", "%#{user.id}%").order(id: :desc).first
      if lastExpense
        lastExpense.destroy
        @bot.api.send_message(chat_id: message.chat.id, text: "Last expense deleted: #{lastExpense.title}, $#{lastExpense.amount}")
      end
    when "/remind"
      if !content.nil?
        handle_reminder_commands(user.id, message.chat.id, content)
      end
    else
      handle_unknown_command(message.chat.id)
    end
  end

  private def handle_reminder_commands(user_id, chat_id, content)
    if content.contains("create")
      _, hour = content.split(" ", 2)
      result = TelegramRemindersService.create_reminder(user_id: user.id, hour: Integer(hour))
      if result.key?(:success)
        @bot.api.send_message(chat_id: chat_id, text: "New reminder created for #{hour}!")
      else
        @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again. #{result.error}")
      end
    elsif content.contains("delete")
      _, hour = content.split(" ", 2)
      TelegramRemindersService.delete_reminder(user_id: user.id, hour: hour)
      if result.key?(:success)
        @bot.api.send_message(chat_id: chat_id, text: "Reminder deleted for #{hour}!")
      else
        @bot.api.send_message(chat_id: chat_id, text: "Sorry, please try again. #{result.error}")
      end
    elsif content.contains ("list")
      maxListed = 10
      remindersArray = TelegramRemindersService.get_reminders_for_user_id(user_id)
      responseString = "Here is your list of reminders!\n\n"
      remindersArray.each_with_index do |expense, i|
        if i < maxListed
          responseString << "#{i+1}: #{reminder.hour}\n"
        end
      end
      if remindersArray.length > maxListed
        responseString << "...\n"
      end
      @bot.api.send_message(chat_id: chat_id, text: responseString)
    end
  end

  private def handle_edited_flow(user, message)
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
