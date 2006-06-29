require 'exceptions'

# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   user.is_member?                     --> Returns true if user has any role of "member"
#   user.is_member_of? this_workshop    --> Returns true/false. Must have authorizable object after query.
#   user.is_eligible_for [this_award]   --> Gives user the role "eligible" for "this_award"
#   user.is_candidate_of_what           --> Returns array of objects for which this user is a "candidate"
module Identity
  module Base
  
    VALID_PREPOSITIONS = 'of|for|in|on|to|at|by'
      
    module InstanceMethods
      def method_missing( method_sym, *args )
        method_name = method_sym.to_s
        authorizable_object = args.empty? ? nil : args[0]
        
        regex = "^is_(\\w+)_(#{VALID_PREPOSITIONS})"
        if method_name =~ Regexp.new(regex + '$') or method_name =~ Regexp.new("^is_(\\w+)$")
          role_name = $1
          is_role( role_name, authorizable_object )
        elsif method_name =~ Regexp.new(regex + '_what$')
          role_name = $1
          has_role_for_objects(role_name)
        elsif method_name =~ Regexp.new(regex + '\?$')
          role_name = $1
          is_role?( role_name, authorizable_object )
        else
          super
        end
      end
      
      private
      
      def is_role?( role_name, authorizable_object )
        if self.respond_to?(:has_role?)
          if authorizable_object.nil?
            return self.has_role?(role_name)
          elsif authorizable_object.respond_to?(:accepts_role?)
            return self.has_role?(role_name, authorizable_object)
          end
        end
        false
      end
      
      def is_role( role_name, authorizable_object = nil )
        if authorizable_object.nil?
          self.has_role role_name
        else
          self.has_role role_name, authorizable_object
        end
      end
      
      def has_role_for_objects(role_name)
        roles = self.roles.find_all_by_name( role_name )
        roles.collect { |role| role.authorizable }
      end
    end
      
  end
end