# Redcrumbs

Fast and unobtrusive activity tracking of ActiveRecord models using Redis and DataMapper.

Redcrumbs is designed for high-traffic applications that need to track changes to their tables without making additional writes to the database. It is especially useful where the saved history needs to be expired over time and is not mission critical data. The emphasis is on reducing response times and easing the load on your main database.

Note: Now compatible with Rails 3.1+ only.

User context is built in and fully customisable and this makes Redcrumbs particularly useful for reporting relevant activity to users as it happens in your app.

Redcrumbs is used for the 'News' feature in Project Zebra games but could also be used as the basis of a fast versioning or reporting system.

For a more complete versioning system see the excellent [vestal_versions](https://github.com/laserlemon/vestal_versions) gem.

Please note, this is early stage stuff. We're not using it in production just yet.

## Installation

Assuming you've got Redis installed and running on your system just add this to your Gemfile:

```
gem 'redcrumbs'
```

Then run the generator to create the initializer file. No migrations necessary!

```
$ rails g redcrumbs:install
```

Done! Look in `config/initializers/redcrumbs.rb` for customisation options.

## Example

Start tracking a model by adding `redcrumbed` to the class:

```
class Venue < ActiveRecord::Base
  redcrumbed :only => [:name, :latlng]
  
  validates :name, :presence => true
  validates :latlng, :uniqueness => true
end
```

And that's pretty much it! Now you can do this:

```
> venue = Venue.last
=> #<Venue id: 1, name: "Belfast City Hall" ... >

> venue.update_attributes(:name => "City Hall, Belfast")
=> #<Venue id: 1, name: "City Hall, Belfast" ... >

> venue.crumbs
=> [#<Crumb id: 34 ... >, #<Crumb id: 42 ... >, #<Crumb id: 53 ... >]

> crumb = venue.crumbs.last
=> #<Crumb id: 53 ... >

> crumb.modifications
=> {"name" => ["Belfast City Hall", "City Hall, Belfast"]}

> crumb.subject
=> #<Venue id: 1, name: "City Hall, Belfast" ... >

```

Not too shabby. But crumbs can also track the user that made the change (creator), and even a secondary user affected by the change (target). By default the creator is considered to be the user associated with the object:

```
> user = User.find(2)
=> #<User id: 2, name: "Jon" ... >

> venue = user.venues.last
=> #<Venue id: 1, name: "City Hall, Belfast", user_id: 2 ... >

> venue.update_attributes(:name => "Halla na Cathrach, Bhéal Feirste")
=> #<Venue id: 1, name: "Halla na Cathrach, Bhéal Feirste", user_id: 2 ... >

> crumb = venue.crumbs.last
=> #<Crumb id: 54 ... >

> crumb.modifications
=> {"name" => ["City Hall, Belfast", "Halla na Cathrach, Bhéal Feirste"]}

> crumb.creator
=> #<User id: 2, name: "Jon" ... >

# and really cool, returns a limited (default 100) array of crumbs affecting a user in reverse order:
> user.crumbs_as_user(:limit => 20)
=> [#<Crumb id: 64 ... >, #<Crumb id: 53 ... >, #<Crumb id: 42 ... > ... ]

# or if you just want the crumbs created by the user
> user.crumbs_by

# or affecting the user
> user.crumbs_for

```

You can customise just what should be considered a creator or target globally across your app by editing a few lines in the redcrumbs initializer. Or you can override the creator and target methods if you want class-specific control:

```
class User < ActiveRecord::Base
  belongs_to :alliance
  has_many :venues
end

class Venue < ActiveRecord::Base
  redcrumbed :only => [:name, :latlng]
  
  belongs_to :user
  
  validates :name, :presence => true
  validates :latlng, :uniqueness => true
  
  def creator
    user.alliance
  end
end
```

## Conditional control

You can pass `:if` and `:unless` options to the redcrumbed method to control when an action should be tracked in the same way you would for an ActiveRecord callback. For example:

```
class Venue < ActiveRecord::Base
  redcrumbed :only => [:name, :latlng], :if => :has_user?
  
  def has_user?
    !!user_id
  end
end
```

## Attribute storage

It's not best practice but since the emphasis is on easing the load on our main database we have bent a few rules in order to reduce the calls on the database to, ideally, zero. In any given app you may be tracking several models and this results in a lot of SQL we could do without.

#### Versions >= 0.3.0

`redcrumbed` accepts a `:store` option to which you can pass a hash of options similar to that of the ActiveRecord `as_json` method. These are attributes of the subject that you'd like to store on the crumb object itself. Use it sparingly if you know that, for example, you are only ever going to really use a couple of attributes of the subject and you want to avoid loading the whole thing from the database.

Examples:

```
class Venue
  redcrumbed :only => [:name, :latlng], :store => {:only => [:id, :name]}
end
```

```
class Venue
  redcrumbed :only => [:name, :latlng], :store => {:except => [:updated_at, :created_at]}
end
```

```
class Venue
  redcrumbed :only => [:name, :latlng], :store => {:only => [:id, :name], :methods => [:checkins]}
end
```

#### Versions  < 0.3.0

`redcrumbed` accepts a `:store` option to which you can pass an array of attributes of the subject that you'd like to store on the crumb object itself. Use it sparingly if you know that, for example, you are only ever going to really use a couple of attributes of the subject and you want to avoid loading the whole thing from the database.

```
class Venue
  redcrumbed :only => [:name, :latlng], :store => [:id, :name]
end
```

#### Using the stored object

So now if you call `crumb.subject` instead of loading the Venue from your database it will instantiate a new Venue with the only the attributes you have stored. You can always retrieve the original by calling `crumb.full_subject`.

_ If you plan to use the `methods` option to store data on the Crumb you should only use it to store attr_accessors unless you won't be instantiating the subject itself _

#### Creator and Target storage

As you might expect, you can also do this for the creator and target of the crumb. See the redcrumbs.rb initializer for how to set this as a global configuration.


## To-do

Lots of refactoring, tests and new features.

## License

Created by John Hope ([@midhir](http://www.twitter.com/midhir)) (c) 2012 for Project Zebra ([@projectzebra](http://www.twitter.com/projectzebra)). Released under MIT License (http://www.opensource.org/licenses/mit-license.php).
