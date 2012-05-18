module Redcrumbs
  module Options
    extend ActiveSupport::Concern
    
    module ClassMethods
      # prepare_redcrumbed_options prepares class level options that customise the behaviour of
      # redcrumbed. See documentation for a full explanation of redcrumbed options.
      def prepare_redcrumbed_options(options)
        cattr_accessor :fields, :store, :if, :unless

        self.fields = []
        self.store = []
        self.if = []
        self.unless = []
        self.fields += Array(options[:only]) unless !options[:only]
        self.store += Array(options[:store]) unless !options[:store]
        self.if += Array(options[:if]) unless !options[:if]
        self.unless += Array(options[:unless]) unless !options[:unless]
      end
    end
  end
end