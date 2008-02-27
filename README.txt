= Authorization plugin

http://www.writertopia.com/developers/authorization

This plugin provides a flexible way to add authorization to Rails.

The authorization process decides whether a user is allowed access to some
feature.  It is distinct from the authentication process, which tries to
confirm a user is authentic, not an imposter. There are many authentication
systems available for Rails, e.g., acts_as_authenticated and LoginEngine. This
authorization system will play nicely with them as long as some simple
requirements are met:

1. User objects are available that implement a <tt>has_role?(role,
   authorizable_object = nil)</tt> method. This requirement can be easily
   handled by using <tt>acts_as_authorized_user</tt> in the User-like class.

2. If you want to use "role of model" authorization expressions, like "owner of
   resource" or "eligible for :award", then your models with roles must
   implement an <tt>accepts_role?(role, user)</tt> method. This requirement can
   be handled by using <tt>acts_as_authorizable</tt> in the model class.

The authorization plugin provides the following:

* A simple way of checking authorization at either the class or instance method
  level using #permit and #permit?

* Authorization using roles for the entire application, a model class, or an
  instance of a model (i.e., a particular object).

* Some english-like dynamic methods that draw on the defined roles. You will be
  able to use methods like "user.is_fan_of angelina" or "angelina.has_fans?",
  where a 'fan' is only defined in the roles table.

* Pick-and-choose a mixin for your desired level of database complexity. For
  all the features, you will want to use "object roles table" (see below)


== Installation

There are currently two recommended ways of installing the plugin into your
Rails application, via Git (Recommended) and a manual install from a .zip file.

Install using Git:

The source code for this plugin is maintained in a Git SCM repository.  This
will always have the latest version of the code and is the recommended source
for installation.  You can install the plugin using Git sub-modules (which are
akin to using SVN externals).  Installing this way allows you to update the
plugin code later if needed (but note that it will not update any generated
code created earlier by this plugin, you would need to do that manually).

From your RAILS_ROOT directory run:

git-submodule add git://github.com/DocSavage/rails-authorization-plugin.git vendor/plugins/authorization

You should be able to update this plugin in the future with a simple 'git
submodule update' from your rails root.

Manual Install:

* Download the latest .zip file of the plugin from RubyForge (
  http://rubyforge.org/frs/?group_id=1797 ) and save it to your
  RAILS_ROOT/vendor/plugins folder.

* Unpack the zip file which should create the directory
  vendor/plugins/authorization

* Remove the original .zip file.


== Steps in using the plugin

1. At the top of your config/environment.rb create an AUTHORIZATION_MIXIN
   constant and set it to "object roles" or "hardwired". (See init.rb in this
   plugin for how the role support is mixed in.)

2. Make sure your application provides a current_user method or something that
   returns the current user object. Add the constants in environment.rb to set
   your authentication system's login page (LOGIN_REQUIRED_REDIRECTION),
   permission denied page (PERMISSION_DENIED_REDIRECTION) and method for
   storing the current URL for return after authentication
   (STORE_LOCATION_METHOD). (See authorization.rb in the plugin's /lib
   directory for the default values of LOGIN_REQUIRED_REDIRECTION,
   PERMISSION_DENIED_REDIRECTION and STORE_LOCATION_METHOD.)

3. If you use the "hardwired" mixin, no database use is required. Otherwise,
   you'll have to generate a role.rb model (and its associated join table with
   User) by running "script/generate role_model Role" and doing "rake migrate".

4. Add <tt>acts_as_authorized_user</tt> to your user class.

5. Add <tt>acts_as_authorizable</tt> to the models you want to query for roles.

== Jumpstarting with a mixin

The Authorization plugin comes with two modules that provide different levels
of database support.  Each of the mixins provide the
<tt>acts_as_authorized_user</tt> and <tt>acts_as_authorizable</tt> class
methods for your models. If you use one of those declarations, you get methods
that handle authorization with different database schemes. A full test web
application is provided for each of the modules so you can see how they
work. The "Object Roles Table" version is recommended for normal use and is the
default.

=== 1) Hardwired Roles

This is the simplest and requires no database. Roles are assumed to be coded
into the Model classes using the <tt>has_role?(role, obj = nil)</tt> method.

=== 2) Object Roles Table

The Object Roles Table mixin provides full support for authorization
expressions within a database by add a polymorphic field to the Role
table. Because roles have polymorphic associations to an authorizable object,
we can assign a user to a role for any model instance. So you could declare
user X to be a moderator for workshop Y, or you could make user A be the owner
of resource B.

The identity module adds a number of dynamic methods that use defined
roles. The user-like model gets methods like <tt>user.is_moderator_of
group</tt> (sets user to "moderator" of <tt>group</tt>),
<tt>user.is_moderator?</tt> (returns true/false if user has some role
"moderator"), and <tt>group.has_moderators</tt> (returns an array of users that
have role "moderator" for the group).  If you prefer not to have these dynamic
methods available, you can simply comment out the inclusion of the identity
module within object_roles_table.rb.

=== Migrations and Testing

Each mixin's test web application comes with migrations to set up the database
for the associated mixin.  After reading the Rails Recipe on domain specific
languages (DSLs) for testing, I added integration tests for each mixin test app
that use a simple vocabulary for testing authorization. The object_roles_test
application has the most tests. Please contribute tests to improve coverage.


== The Specifics

=== permit and permit?

permit and permit? take an authorization expression and a hash of options that
typically includes any objects that need to be queried:

  permit <authorization expression> [, options hash ]
  permit? <authorization expression> [, options hash ]

The difference between permit and permit? is redirection. permit is a
declarative statement and redirects by default. It can also be used as a class
or an instance method, gating the access to an entire controller in a
before_filter fashion.

permit? is only an instance method, can be used within expressions, does not
redirect by default.

The authorization expression is a boolean expression made up of permitted
roles, prepositions, and authorizable models. Examples include "admin" (User
model assumed), "moderator of :workshop" (looks at options hash and then
@workshop), "'top salesman' at :company" (multiword roles delimited by single
quotes), or "scheduled for Exam" (queries class method of Exam).

Note that we can use several permitted prepositions ('of', 'for', 'in', 'on',
'to', 'at', 'by'). In the discussion below, we assume you use the "of"
preposition. You can modify the permitted prepositions by changing the constant
in Authorization::Base::Parser.

* If a specified role has no "of <model>" designation, we assume it is a user
  role (i.e., the model is the user-like object).

* If an "of model" designation is given but no "model" key/value is supplied in
  the hash, we check if an instance variable @model if it's available.

* If the model is capitalized, we assume it's a class and query
  <tt>Model#self.accepts_role?</tt> (the class method) for the
  permission. (Currently only available in ObjectRolesTable mixin.)

For each role, a query is sent to the appropriate model object.

The grammar for the authorization expression is:

         <expr> ::= (<expr>) | not <expr> | <term> or <expr> | <term> and <expr> | <term>
         <term> ::= <role> | <role> <preposition> <model>
  <preposition> ::= of | for | in | on | to | at | by
        <model> ::= /:*\w+/
         <role> ::= /\w+/ | /'.*'/

Parentheses should be used to clarify permissions. Note that you may prefix the
model with an optional ":" -- the first versions of Authorization plugin made
this mandatory but it's now optional since the mandatory preposition makes
models unambiguous.

==== Options

<tt>:allow_guests => false</tt>. We can allow permission processing without a
current user object. The default is <tt>false</tt>.

<tt>:user</tt> => A <tt>user</tt> object.

<tt>:get_user_method => method</tt> that will return a <tt>user</tt>
object. Default is <tt>#current_user</tt>, which is the how
<tt>acts_as_authenticated</tt> works.

<tt>:only => [ :method1, :method2 ]</tt>. Array of methods to apply permit (not
valid when used in instance methods)

<tt>:except => [ :method1, :method2 ]</tt>. Array of methods that won't have
permission checking (not valid when used in instance methods)

<tt>:redirect => bool</tt>. default is <tt>true</tt>. If <tt>false</tt>, permit
will not redirect to denied page.

<tt>:login_required_redirection => path or hash</tt> where user will be
redirected if not logged in (default is "{ :controller => 'session', :action =>
'new' }")

<tt>:login_required_message => 'my message'</tt> (default is 'Login is required
to access the requested page.')

<tt>:permission_denied_redirection => path or hash</tt> where user will be
redirected if logged in but not authorized (default is '')

<tt>:permission_denied_message => 'my message</tt> (default is 'Permission
denied. You cannot access the requested page.')

=== Setting and getting the roles

Roles are set by #has_role and #accepts_role methods that are mixed into the
User-like object and the authorizable models. User objects can set roles and
optionally an object scope for that role:

  user.has_role 'site_admin'
  user.has_role 'moderator', group
  user.has_no_role 'site_admin'
  user.has_no_role 'moderator', group
  user.has_role 'member', Group

Note that the last method sets role "member" on a class "Group". Roles can be
set with three scopes: entire application (no class or object specified), a
model class, or an instance of a model (i.e., a model object).

Models set roles for specific users:

  a_model.accepts_role 'moderator', user
  a_model.accepts_no_role 'moderator', user
  Model.accepts_role 'class moderator', user

The method language has been chosen to aid memory of the argument order. A user
has a role "foo", so the role string immediately follows has_role. Similarly, a
model accepts a role "foo", so the role string immediately follows
accepts_role. Then we append the scope.

Sometimes the user-like object might be an authorizable object as well, for example, when you
allow 'friend' roles for users. In this case, the user-like object can be declared to be
<tt>acts_as_authorizable</tt> as well as <tt>acts_as_authorized_user</tt>.

Role queries follow the same pattern as the setting of roles:

  user.has_role? 'moderator'
  user.has_role? 'moderator', group
  user.has_role? 'member', Group

  a_model.accepts_role? 'moderator', user
  Model.accepts_role? 'moderator', user

When a user is queried without specifying either a model class or object, it
returns true if the user has *any* matching role. For example,
<tt>user.has_role? 'moderator'</tt> returns true if the user is 'moderator' of
a class, a model object, or just a generic 'moderator'.  Note that if you say
<tt>user.has_role 'moderator'</tt>, the user does not become 'moderator' for
all classes and model objects; the user simply has a generic role 'moderator'.

==== Dynamic methods through the Identity mixin

The Object Roles Table version includes some dynamic methods that use the roles
table.  For example, if you have roles like "eligible", "moderator", and
"owner", you'll be able to use the following:

  user.is_eligible_for_what   --> returns array of authorizable objects for which user has role "eligible"
  user.is_moderator_of? group --> returns true/false
  user.is_moderator_of group  --> sets user to have role "moderator" for object group.
  user.is_administrator       --> sets user to have role "administrator" not really tied to any object.

Models get has_* methods:

  group.has_moderators  --> returns array of users with role "moderator" on that group
  group.has_moderators? --> returns true/false

Allowed prepositions are optional in the above dynamic methods. They are simply
syntactic sugar.  For example, the following are equivalent:

  user.is_member_of group
  user.is_member_for group
  user.is_member group

Allowed prepositions are required in the authorization expressions because they
are used to distinguish "role" and "role of :model" and "role of Model".

If you prefer not to pollute your namespace with these dynamic methods, do not
include the Identity module in <tt>object_roles_table.rb</tt>.

=== Pattern of use

We expect the application to provide the following methods:

==== #current_user

Returns some user object, like an instance of my favorite class,
<tt>UserFromMars</tt>.  A <tt>user</tt> object, from the Authorization
viewpoint, is simply an object that provides a <tt>has_role?</tt> method.

Note that duck typing means we don't care what else the <tt>UserFromMars</tt>
might be doing.  We only care that we can get an id from whatever it is, and we
can check if a given role string is associated with it. By using
<tt>acts_as_authorized_user</tt>, we inject what we need into the user object.

If you use an authorization expression "admin of :foo", we check permission by
asking <tt>foo</tt> if it <tt>accepts_role?('admin', user)</tt>. So for each
model that is used in an expression, we assume that it provides the
<tt>accepts_role?(role, user)</tt> method.

Note that <tt>user</tt> can be <tt>nil</tt> if <tt>:allow_guests => true</tt>.

==== #store_location (optional)

This method will be called if authorization fails and the user is about to be
redirected to the login action. This allows the application to return to the
desired page after login.  If the application doesn't provide this method, the
method will not be called.

The name of the method for storing a location can be modified by changing the
constant STORE_LOCATION_METHOD in environment.rb. Also, the default login and
permission denied pages are defined by the constants LOGIN_REQUIRED_REDIRECTION
and PERMISSION_DENIED_REDIRECTION in authorization.rb and can be overriden in
your environment.rb.

=== Conventions

Roles specified without the "of model" designation:

1. We see if there is a <tt>current_user</tt> method available that will return
   a user object. This method can be overridden with the <tt>:user</tt> hash.

2. Once a user object is determined, we pass the role to
   <tt>user.has_role?</tt> and expect a true return value if the user has the
   given role.

Roles specified with "of model" designation:

1. We attempt to query an object in the options hash that has a matching
   key. Example: <tt>permit "knight for justice", :justice =>
   @abstract_idea</tt>

2. If there is no object with a matching key, we see if there's a matching
   instance variable. Example: @meeting defined before we use <tt>permit
   "moderator of meeting"</tt>

3. Once the model object is determined, we pass the role and user (determined
   in the manner above) to <tt>model.accepts_role?</tt>

=== More information

Information on this plugin and other development can be found at
http://www.writertopia.com/developers
