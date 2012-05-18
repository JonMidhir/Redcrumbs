# Redcrumbs

Fast and unobtrusive tracking of ActiveRecord models using Redis and DataMapper.

Redcrumbs is designed for high-traffic applications that need to track changes to their tables without making additional writes to the database. It is especially useful where the saved history needs to be expired over time and is not mission critical data. The emphasis is on speed rather than versatility.

User context is built in and fully customisable and this makes Redcrumbs particularly useful for reporting changes to users as they happen in your app.

Redcrumbs is used for the 'News' feature in Project Zebra games but could also be used as the basis of a fast versioning or reporting system.

For a more complete versioning system see the excellent [vestal_versions](https://github.com/laserlemon/vestal_versions) gem.

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