source 'https://rubygems.org'

gem 'activerecord', '~> 4.1'
gem 'activesupport', '~> 4.1'

gemspec :path => '..'

group :test do
  gem 'rspec', '~> 2.0'
  gem 'sqlite3', '~> 1.0'
end