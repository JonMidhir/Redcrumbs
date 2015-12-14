require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'redcrumbs'

require 'bundler'
Bundler.require(:test)

RSpec.configure do |c|
  c.before(:suite) do
    Redcrumbs.redis = 'localhost:6379'
    I18n.config.enforce_available_locales = true
    CreateSchema.suppress_messages{ CreateSchema.migrate(:up) }
  end

  c.before(:each) do
    Redcrumbs.redis.flushdb
  end

  c.after(:suite) do
    Redcrumbs.redis.flushdb
  end

  c.mock_with :rspec

  c.filter_run focus: true
  c.run_all_when_everything_filtered = true

end

Dir[File.expand_path('../support/*.rb', __FILE__)].each{|f| require f }