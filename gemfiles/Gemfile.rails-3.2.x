source 'https://rubygems.org'

gem 'activerecord', '~> 3.2'
gem 'activesupport', '~> 3.2'

gemspec :path => '..'

group :test do
  gem 'rspec', '~> 3.0'
  gem 'sqlite3', '~> 1.0'
end