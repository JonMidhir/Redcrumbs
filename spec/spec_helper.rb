require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'redcrumbs'

require 'bundler'
Bundler.require(:test)

RSpec.configure do |c|
  c.before(:suite) do
    CreateSchema.suppress_messages{ CreateSchema.migrate(:up) }
    Redcrumbs.creator_class_sym = :player
    Redcrumbs.target_class_sym = :player
  end

  c.after(:each) do
    Redcrumbs.redis.flushdb
  end

  c.mock_with :rspec
end

Dir[File.expand_path('../support/*.rb', __FILE__)].each{|f| require f }