# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Expense.destroy_all
User.destroy_all

4.times do
  User.create(
    email: Faker::Internet.email,
    password_hash: Faker::Alphanumeric.alphanumeric(number: 50),
  )
end

200.times do
  Expense.create(
    amount: rand(1.00..100.00).round(2),
    user_id: User.ids.sample,
    time: Faker::Time.backward(days: 180)
  )
end
