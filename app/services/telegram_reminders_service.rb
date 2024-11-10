# This file contains CRUD methods for Telegram bot reminders

class TelegramRemindersService
  def self.create_reminder(user_id: string, hour: int)
    reminder = Reminder.create(user: user_id, hour: hour)
    if reminder.persisted?
      { success: reminder }
    else
      { error: reminder.errors.full_messages }
    end
  end

  def self.delete_reminder(user_id: string, hour: int)
    reminder = Reminder.find_by(user: user_id, hour: hour)
    if reminder
      reminder.destroy
      { success: "Successfully destroyed" }
    else
      { error: "Reminder not found" }
    end
  end

  def self.get_user_ids_for_current_hour
    current_hour = Time.now.hour
    Reminder.where(hour: current_hour).pluck(:user)
  end
end
