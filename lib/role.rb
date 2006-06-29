if AUTHORIZATION_MIXIN == "simple roles"
  class Role < ActiveRecord::Base
    has_and_belongs_to_many :users
  end
elsif AUTHORIZATION_MIXIN == "object roles"
  class Role < ActiveRecord::Base
    has_and_belongs_to_many :users
    belongs_to :authorizable, :polymorphic => true
  end
end

