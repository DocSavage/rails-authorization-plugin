require 'exceptions'

# In order to use this mixin, you'll need the following:
# 1. A Role class with proper associations
# 2. Database tables that support the roles. A sample migration is
#    supplied below
# 
# create_table "roles_users", :id => false, :force => true, :index => false do |t|
#   t.column :user_id,          :integer
#   t.column :role_id,          :integer
#   t.column :created_at,       :datetime
#   t.column :updated_at,       :datetime
# end
# 
# create_table "roles", :force => true do |t|
#   t.column :name,             :string, :limit => 40
#   t.column :created_at,       :datetime
#   t.column :updated_at,       :datetime
# end
 

module Authorization
  module SimpleRolesTable
  
    module UserExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def acts_as_authorized_user
          has_and_belongs_to_many :roles
          include Authorization::SimpleRolesTable::UserExtensions::InstanceMethods
        end
      end
      
      module InstanceMethods
        # If roles aren't explicitly defined in user class then check roles table
        def has_role?( role, authorizable_object = nil )
          self.roles.find_by_name( role ) ? true : false
        end
        
        def has_role( role_name, authorizable_object = nil )
          role = self.roles.find_by_name( role_name )
          if role.nil?
            role ||= Role.find_or_create_by_name( role_name )
            self.roles << role
          end
        end
        
        def has_no_role( role_name, authorizable_object = nil )
          role = self.roles.find_by_name( role_name )
          self.roles.delete( role ) if role
        end
      end 
    end
    
    module ModelExtensions
      def self.included( recipient )
        recipient.extend( ClassMethods )
      end
      
      module ClassMethods
        def acts_as_authorizable
          include Authorization::SimpleRolesTable::ModelExtensions::InstanceMethods          
          # We don't really have to define habtm relationship from Role to User-like object because we don't need it for authorization
          
          def accepts_role?( role_name, user )
            user.has_role?( role_name, self )
          end
          
          def accepts_role( role, user )
            raise( CannotSetObjectRoleWhenSimpleRoleTable, 
              "Simple role table mixin: Cannot give user a role #{role} for a model class. Don't use #accepts_role, use code in models."
            )
          end

          def accepts_no_role( role, user )
            raise( CannotSetObjectRoleWhenSimpleRoleTable, 
              "Simple role table mixin: Cannot remove a role #{role} for a model class. Don't use #accepts_no_role, use code in models."
            )
          end
        end
      end
      
      module InstanceMethods
        # If roles aren't overriden in model then check roles table
        def accepts_role?( role_name, user )
          user.roles.find_by_name( role_name ) ? true : false
        end
        
        # We don't have permit_set for simple roles table because roles aren't defined on each model instance.
        def accepts_role( role, user )
          raise( CannotSetObjectRoleWhenSimpleRoleTable, 
            "Simple role table mixin: Cannot give user a role #{role} for specific model instance. Don't use #accepts_role, use code in models."
          )
        end
        
        def accepts_no_role( role, user )
          raise( CannotSetObjectRoleWhenSimpleRoleTable, 
            "Simple role table mixin: Cannot remove a role #{role} for a user on a specific model instance. Don't use #accepts_no_role, use code in models."
          )
        end
      end 
    end
    
  end
end

