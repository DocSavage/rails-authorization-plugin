require 'exceptions'
require 'identity'

# In order to use this mixin, you'll need the following:
# 1. A Role class with proper associations (habtm to User-like class)
# 2. Database tables that support the roles. A sample migration is
#    supplied below
#
# create_table "roles_users", :id => false, :force => true  do |t|
#   t.column :user_id,          :integer
#   t.column :role_id,          :integer
#   t.column :created_at,       :datetime
#   t.column :updated_at,       :datetime
# end
# 
# create_table "roles", :force => true do |t|
#   t.column :name,               :string, :limit => 40
#   t.column :authorizable_type,  :string, :limit => 30
#   t.column :authorizable_id,    :integer
#   t.column :created_at,         :datetime
#   t.column :updated_at,         :datetime
# end
 
module Authorization
  module ObjectRolesTable
  
    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def acts_as_authorized_user
          has_and_belongs_to_many :roles
          include Authorization::ObjectRolesTable::UserExtensions::InstanceMethods
          include Authorization::Identity::UserExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end
      
      module InstanceMethods
        # If roles aren't explicitly defined in user class then check roles table
        def has_role?( role_name, authorizable_obj = nil )
          if authorizable_obj.nil?
            self.roles.find_by_name( role_name ) ? true : false    # If we ask a general role question, return true if any role is defined.
          else
            role = get_role( role_name, authorizable_obj )
            self.roles.include? role
          end
        end
        
        def has_role( role_name, authorizable_obj = nil )
          role = get_role( role_name, authorizable_obj )
          if role.nil?
            if authorizable_obj.is_a? Class
              role = Role.create( :name => role_name, :authorizable_type => authorizable_obj.to_s )
            elsif authorizable_obj
              role = Role.create( :name => role_name, :authorizable => authorizable_obj )
            else
              role = Role.create( :name => role_name )
            end
          end
          self.roles << role if not self.roles.include?( role )
        end
        
        def has_no_role( role_name, authorizable_obj = nil  )
          role = get_role( role_name, authorizable_obj )
          if role
            self.roles.delete( role )
            role.destroy if role.users.empty?
          end
        end

        private
        
        def get_role( role_name, authorizable_obj )
          if authorizable_obj.is_a? Class
            Role.find( :first, 
                       :conditions => [ 'name = ? and authorizable_type = ? and authorizable_id IS NULL', role_name, authorizable_obj.to_s ] )
          elsif authorizable_obj
            Role.find( :first, 
                       :conditions => [ 'name = ? and authorizable_type = ? and authorizable_id = ?', 
                                        role_name, authorizable_obj.class.to_s, authorizable_obj.id ] )
          else
            Role.find( :first, 
                       :conditions => [ 'name = ? and authorizable_type IS NULL and authorizable_id IS NULL', role_name ] )
          end
        end
        
      end 
    end
        
    module ModelExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def acts_as_authorizable
          has_many :accepted_roles, :as => :authorizable, :class_name => 'Role'
          
          def accepts_role?( role_name, user )
            user.has_role? role_name, self 
          end
          
          def accepts_role( role_name, user )
            user.has_role role_name, self
          end
          
          def accepts_no_role( role_name, user )
            user.has_no_role role_name, self
          end
          
          include Authorization::ObjectRolesTable::ModelExtensions::InstanceMethods
          include Authorization::Identity::ModelExtensions::InstanceMethods   # Provides all kinds of dynamic sugar via method_missing
        end
      end
      
      module InstanceMethods
        # If roles aren't overriden in model then check roles table
        def accepts_role?( role_name, user )
          user.has_role? role_name, self
        end
        
        def accepts_role( role_name, user )
          user.has_role role_name, self
        end
        
        def accepts_no_role( role_name, user )
          user.has_no_role role_name, self
        end
      end    
    end
    
  end
end

