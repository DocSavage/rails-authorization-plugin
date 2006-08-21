if AUTHORIZATION_MIXIN == "simple roles"
  class Role < ActiveRecord::Base
    has_and_belongs_to_many :users
  end
elsif AUTHORIZATION_MIXIN == "object roles"
  # The Role model defines named roles for users that may be applied to
  # objects in a polymorphic fashion. For example, you could create a role
  # "moderator" for an instance of a model (i.e., an object), a model class,
  # or without any specification at all.
  class Role < ActiveRecord::Base
    has_and_belongs_to_many :users
    belongs_to :authorizable, :polymorphic => true
  end
end

