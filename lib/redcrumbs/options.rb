module Redcrumbs
  module Options
    extend ActiveSupport::Concern
    
    module ClassMethods
      # prepare_redcrumbed_options prepares class level options that customise the behaviour of
      # redcrumbed. See documentation for a full explanation of redcrumbed options.
      def prepare_redcrumbed_options(options)
        cattr_accessor :fields, :store, :if, :unless
        
        defaults = {
          :fields => [],
          :store => [],
          :if => [],
          :unless => []
        }
        
        options.reverse_merge!(defaults)
        
        self.fields = Array(options[:only])
        self.store = Array(options[:store])
        self.if = options[:if]
        self.unless = options[:unless]
      end
    end
  end
end