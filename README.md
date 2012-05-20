# Redcrumbs

Fast and unobtrusive activity tracking of ActiveRecord models using Redis and DataMapper.

Redcrumbs is designed for high-traffic applications that need to track changes to their tables without making additional writes to the database. It is especially useful where the saved history needs to be expired over time and is not mission critical data. The emphasis is on speed rather than versatility.

User context is built in and fully customisable and this makes Redcrumbs particularly useful for reporting changes to users as they happen in your app.

Redcrumbs is used for the 'News' feature in Project Zebra games but could also be used as the basis of a fast versioning or reporting system.

For a more complete versioning system see the excellent [vestal_versions](https://github.com/laserlemon/vestal_versions) gem.

Please note, this is early stage stuff. We're not using it in production just yet.

## Installation

In your Gemfile:

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

## To-do

Lots of refactoring, tests and new features.
