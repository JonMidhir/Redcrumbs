require 'redcrumbs'

require 'bundler'
Bundler.require(:test)

RSpec.configure do |c|
  c.before(:suite) do
    CreateSchema.suppress_messages{ CreateSchema.migrate(:up) }
  end

  c.mock_with :rspec
end

Dir[File.expand_path('../support/*.rb', __FILE__)].each{|f| require f }