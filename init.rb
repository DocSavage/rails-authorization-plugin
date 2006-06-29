require File.dirname(__FILE__) + '/lib/authorization'

ActionController::Base.send( :include, Authorization::Base )
ActionView::Base.send( :include, Authorization::Base::ControllerInstanceMethods )

# You can perform authorization at varying degrees of complexity.
# Choose a style of authorization below (see README) and the appropriate
# mixin will be used for your app.

# When used with the auth_test app, we define this in config/environment.rb
# AUTHORIZATION_MIXIN = "hardwired"
if not Object.constants.include? AUTHORIZATION_MIXIN
  AUTHORIZATION_MIXIN = "object roles"
end

case AUTHORIZATION_MIXIN
  when "hardwired"
    require File.dirname(__FILE__) + '/lib/hardwired_roles'
    ActiveRecord::Base.send( :include, 
      Authorization::HardwiredRoles::UserExtensions, 
      Authorization::HardwiredRoles::ModelExtensions 
    )
  when "simple roles"
    require File.dirname(__FILE__) + '/lib/simple_roles_table'
    require File.dirname(__FILE__) + '/lib/role.rb'
    ActiveRecord::Base.send( :include, 
      Authorization::SimpleRolesTable::UserExtensions, 
      Authorization::SimpleRolesTable::ModelExtensions 
    )
  when "object roles"
    require File.dirname(__FILE__) + '/lib/object_roles_table'
    require File.dirname(__FILE__) + '/lib/identity'              # Dynamic methods on the roles table (see identity.rb)
    ActiveRecord::Base.send( :include, 
      Authorization::ObjectRolesTable::UserExtensions, 
      Authorization::ObjectRolesTable::ModelExtensions,
      Identity::Base::InstanceMethods
    )
end
