require 'exceptions'
require 'parser'

module Authorization
  module Base
  
    # Modify these constants to tailor the plugin to your authentication system
    DEFAULT_REDIRECTION_HASH = { :controller => 'account', :action => 'login' }
    STORE_LOCATION_METHOD = :store_return_location

    def self.included( recipient )
      recipient.extend( ControllerClassMethods )
      recipient.class_eval do
        include ControllerInstanceMethods
      end
    end
    
    module ControllerClassMethods
      
      # Allow class-level authorization check.
      # permit is used in a before_filter fashion and passes arguments to the before_filter. 
      def permit( auth_expr, *args )
        filter_keys = [ :only, :except ]
        filter_args, eval_args = {}, {}
        if args.last.is_a? Hash
          filter_args.merge!( args.last.reject {|k,v| not filter_keys.include? k } ) 
          eval_args.merge!( args.last.reject {|k,v| filter_keys.include? k } ) 
        end
        prepend_before_filter( filter_args ) do |controller|
          controller.permit( auth_expr, eval_args )
        end      
      end
    end
    
    module ControllerInstanceMethods
      include Authorization::Base::RecursiveDescentParser  #EvalParser
      
      # Allow method-level authorization checks.
      # permit (without a question mark ending) calls redirect on denial by default.
      # Specify :redirect => false to turn off redirection.
      def permit( authorization_expression, *args )
        @options = { :allow_guests => false, :redirect => true }
        @options.merge!( args.last.is_a?( Hash ) ? args.last : {} )
        
        @current_user = get_user
        if not @options[:allow_guests]
          if @current_user.nil?  # We aren't logged in, or an exception has already been raised
            handle_redirection if @options[:redirect]
            return false
          elsif not @current_user.respond_to? :id
            raise( UserDoesntImplementID, "User doesn't implement #id")
            return false
          elsif not @current_user.respond_to? :has_role?
            raise( UserDoesntImplementRoles, "User doesn't implement #has_role?" )
            return false
          end
        end
        
        # Parse and evaluate the authorization expression
        has_permission = parse_authorization_expression( authorization_expression )
        if has_permission
          yield if block_given?
        elsif @options[:redirect]
          handle_redirection
        end
        has_permission
      end
      
      # Permit? turns off redirection by default.
      def permit?( authorization_expression, *args, &blk )
        if args.last.is_a? Hash
          args.last[:redirect] = false
        else
          args << { :redirect => false }
        end
        permit( authorization_expression, *args, &blk )
      end
      
      private
      
      # Handle redirection within permit if authorization is denied.
      def handle_redirection
        return if not self.respond_to?( :redirect_to )
        redirection = DEFAULT_REDIRECTION_HASH
        redirection[:controller] = @options[:redirect_controller] if @options[:redirect_controller]
        redirection[:action] = @options[:redirect_action] if @options[:redirect_action]
    
        # Store url in session for return if this is available from authentication
        send( STORE_LOCATION_METHOD ) if respond_to? STORE_LOCATION_METHOD
        if @current_user
          flash[:notice] = "Permission denied. Your account cannot access the requested page."
        else
          flash[:notice] = "Login is required"
        end
        redirect_to redirection 
      end

      # Try to find current user by checking options hash and instance method in that order.
      def get_user
        if @options[:user]
          @options[:user]
        elsif @options[:get_user_method]
          send( @options[:get_user_method] )
        elsif methods.include? "current_user"
          current_user
        elsif not @options[:allow_guests]
          raise( CannotObtainUserObject, "Couldn't find #current_user or @user, and nothing appropriate found in hash" )
        end
      end
      
      # Try to find a model to query for permissions
      def get_model( str )
        if str =~ /\s*^:(\w+)\s*/
          # Handle ":model" cases
          model_name = $1
          model_symbol = model_name.to_sym
          if @options[model_symbol]
            @options[model_symbol]
          elsif instance_variables.include?( '@'+model_name )
            instance_variable_get( '@'+model_name )
          # Note -- while the following code makes autodiscovery more convenient, it's a little too much side effect & security question
          # elsif self.params[:id]
          #  eval_str = model_name.camelize + ".find(#{self.params[:id]})"
          #  eval eval_str
          else
            raise CannotObtainModelObject, "Couldn't find model (#{str}) in hash or as an instance variable"
          end
        else
          # Handle model class
          begin
            Module.const_get( str )
          rescue
            raise CannotObtainModelClass, "Couldn't find model class: #{str}"
          end
        end
      end
    end
      
  end
end