source 'https://rubygems.org'

gem 'rails', '~> 4.0'

gemspec :path => '..'

group :test do
  gem 'rspec', '~> 2.0'
  gem 'sqlite3', '~> 1.0'
end