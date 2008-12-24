# The table that links roles with users (generally named RoleUser.rb)
class <%= (class_name < 'User') ? "#{class_name}User" : "User#{class_name}" %> < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end
