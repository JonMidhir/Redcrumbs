# Redcrumbs

[![Build Status](https://travis-ci.org/JonMidhir/Redcrumbs.svg?branch=master)](https://travis-ci.org/JonMidhir/Redcrumbs)
[![Code Climate](https://codeclimate.com/github/JonMidhir/Redcrumbs/badges/gpa.svg)](https://codeclimate.com/github/JonMidhir/Redcrumbs)
[![Test Coverage](https://codeclimate.com/github/JonMidhir/Redcrumbs/badges/coverage.svg)](https://codeclimate.com/github/JonMidhir/Redcrumbs)
[![Dependency Status](https://gemnasium.com/JonMidhir/Redcrumbs.svg)](https://gemnasium.com/JonMidhir/Redcrumbs)

Fast and unobtrusive activity tracking of ActiveRecord models using Redis and DataMapper.

Redcrumbs is designed to make it easy to start generating activity feeds in your application using Redis as a back-end.

Introducing activity feeds can come at significant cost, increasing the number of writes to your primary datastore across many controller actions - sometimes when previously only reads were being performed. Activity feeds have their own characteristics too; they're often not mission critical data, expirable over time and queried in predictable ways.

It turns out Redis is an ideal solution. Super fast to write to and read from and with Memcached-style key expiration built in, leaving your primary database to focus on the business logic.


## Installation

You'll need access to a [Redis](http://redis.io) server running locally, remotely or from a managed service; such as [Redis Labs](https://redislabs.com/).

Add the Gem to your Gemfile:

```ruby
gem 'redcrumbs'
```

Then run the generator to create the initializer file.

```sh
$ rails g redcrumbs:install
```

Done! Look in `config/initializers/redcrumbs.rb` for customisation options.


## Getting Started

Start tracking a model by adding `redcrumbed` to the class:

```ruby
class Game < ActiveRecord::Base
  redcrumbed :only => [:name, :highscore]

  validates :name, :presence => true
  validates :highscore, :presence => true
end
```

That's all you need to get started. `Game` objects will now start generating activities when their `name` or `highscore` attributes are updated.


```ruby
game = Game.last
=> #<Game id: 1, name: "Paperboy" ... >

game.update_attributes(:name => "Paperperson")
=> #<Game id: 1, name: "Paperperson" ... >
```

Activities are objects of class `Crumb` and contain all the data you need to find out about what has changed in the update.


```ruby
crumb = game.crumbs.last
=> #<Crumb id: 53 ... >

crumb.modifications
=> {"name" => ["Paperboy", "Paperperson"]}

```

The `.crumbs` method shown here is available to any class that is `redcrumbed`. It is just a DataMapper collection and you can use it to construct any queries you like. For example, to get the last 10 activities on `game`:

```ruby
game.crumbs.all(:order => :created_at.desc, :limit => 10)
```

## Creating a HTML activity feed

Redcrumbs doesn't provide any helpers to turn crumbs into translated text or HTML views but this is extremely easy to do once you're set up and creating activities.

Now that we know how to get the most recent activities associated with an object we just need to create a helper to translate these into readable text or HTML. Crumbs have a `subject` association that gives you access to the original object. This is useful when you need access to attributes that aren't in the modifications hash.

Here's an example of a simple text helper:

```ruby
module ActivityHelper
  def activity_text_from(crumb)
    modifications = crumb.modifications

    message = 'Someone '

    fragments = []
    fragments << "set a highscore of #{modifications['highscore'][1]}" if modifications.has_key?('highscore')

    if modifications.has_key?('name')
      fragments << "renamed #{modifications['name'][0]} to #{modifications['name'][1]}"
    else
      fragments[0] += " at #{crumb.subject.name}"
    end

    message += fragments.to_sentence
    message += '.'
  end
end
```

And examples of its output:

```
"Someone renamed Paperboy to Paperperson."
"Someone set a highscore of 19840 at Paperperson."
"Someone set a highscore of 21394 at Paperperson and renamed Paperperson to I WIN NOOBS."
```


## User context

Simply reporting that 'Someone did xyz' isn't very useful, so Redcrumbs has user context baked in.

#### Whodunnit?

Crumbs can track the user that made the change (or any object really) as `creator`, and even a secondary user affected by the change as `target`. You simply define methods called `creator` and `target` on the subject class that return the corresponding object:

```ruby
class Game < ActiveRecord::Base
  redcrumbed :only => [:name, :highscore]

  has_one :high_scorer, class_name: 'Player'

  def creator
    high_scorer
  end
end
```

To get the creator and target of a crumb:

     crumb.creator
     => #<Player id: 394 ...>

     crumb.target
     => #<ComputerPlayer id: 3 ...>


#### Querying user activity

As you'd expect you can also grab all the activities affecting a user.

```ruby
# Activities created by a user
player.crumbs_by
```

```ruby
# Activities targeting a user
player.crumbs_for
```

```ruby
# All activities affecting a user
player.crumbs_as_user
```

## Advanced Options

#### Conditional control

You can pass `:if` and `:unless` options to the redcrumbed method to control when an action should be tracked in the same way you would for an ActiveRecord callback. For example, if you only want to track activity _after_ a game has been created:

```ruby
class Game < ActiveRecord::Base
  redcrumbed :only => [:name, :highscore], :unless => :new_record?

  #...
end
```

#### Attribute storage

In many cases to assemble your feed you'll only ever need the `modifications` made to an object plus a couple of common attributes; such as `name` or `id`. When this is the case you can avoid loading the subject from the database entirely by storing those attributes on the crumb itself.

```ruby
class Game < ActiveRecord::Base
  redcrumbed :only => [:name, :highscore], :store => {:only => [:id, :name]}

  #...
end
```

Now when you call `crumb.subject` you will get an instance of `Game` with only the `:id` and `:name` attributes set. If you need the full object you can always load it fully from the database by calling `crumb.full_subject`.

<blockquote>
Note: Be careful using this. The tradeoff is bloat. You will get fewer Redis keys per megabyte. An :except option is available instead of :only but its use is not advised.</blockquote>

#### Creator / Target storage

Similarly to __attribute storage__ above, you can store properties of the `creator` and `target` on the crumb to avoid having to load them from the database. These attributes can only be set globally in the initialization file. Since these objects can differ wildly from model to model this only works when they share some common attributes.

For example a photo might be _created_ by a `User` or an event by a `UserGroup`. If both objects had `:id` and `:name` attributes, for example, you could store these.

The usual warnings apply. However, by combining this with __attribute storage__ it's possible to return multiple activity feeds without touching the primary datastore!

## Changes since v0.4.9
- Key mortality works.
- No longer adding `creator` according to initializer options.
- More robust Redis assignment.
- Support for Redis Namespaces.
- Major refactor.
- Decent test coverage.

## Compatibility
Tested against:
- Ruby 1.9.3 to 2.1.0
- ActiveRecord 3.1 to 4.1

## To-do

Allow swapping out the backend to mongo or other key value stores.

## Testing

Running tests requires a redis server to be running on the local machine with access over port 6379.
Run tests with `bundle exec rspec`.

## License

Created by John Hope ([@midhir](http://www.twitter.com/midhir)) for Project Zebra ([@projectzebra](http://www.twitter.com/projectzebra)) (c) 2014. Released under MIT License (http://www.opensource.org/licenses/mit-license.php).
