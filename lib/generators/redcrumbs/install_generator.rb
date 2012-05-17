module Redcrumbs
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("./templates", __FILE__)

      # all public methods in here will be run in order
      def add_redcrumbs_initializer
        template "initializer.rb", "config/initializers/redcrumbs.rb"
      end
    end
  end
end