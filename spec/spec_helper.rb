require 'redcrumbs'

require 'bundler'
Bundler.require(:test)

RSpec.configure do |c|
  c.before(:suite) do
    CreateSchema.suppress_messages{ CreateSchema.migrate(:up) }
  end

  c.after(:suite) do
    FileUtils.rm_rf(File.expand_path('../test.db', __FILE__))
  end

  c.after(:each) do
    Redcrumbs.redis.flushdb
  end

  c.mock_with :rspec
end

Dir[File.expand_path('../support/*.rb', __FILE__)].each{|f| require f }