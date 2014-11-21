source 'https://rubygems.org'

gem 'activerecord', '~> 4.0'
gem 'activesupport', '~> 4.0'

gemspec :path => '..'

group :test do
  gem 'rspec', '~> 3.0'
  gem 'sqlite3', '~> 1.0'
end