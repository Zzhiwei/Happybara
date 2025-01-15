module TelegramBot::Commands
  class TagCommand < Command
    def initialize(bot, message, user)
      super(bot, message, user)
    end

    def execute
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

    def chat_id
      @message.chat.id
    end
  end
end
