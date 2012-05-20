# Redcrumbs

Fast and unobtrusive activity tracking of ActiveRecord models using Redis and DataMapper.

Redcrumbs is designed for high-traffic applications that need to track changes to their tables without making additional writes to the database. It is especially useful where the saved history needs to be expired over time and is not mission critical data. The emphasis is on speed rather than versatility.

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

> crumb = venue.crumbs.first
=> #<Crumb id: 53 ... >

> crumb.modifications
=> {"name" => ["Belfast City Hall", "City Hall, Belfast"]}

> crumb.subject
=> #<Venue id: 1, name: "City Hall, Belfast" ... >

```

## To-do

Lots of refactoring, tests and new features.
