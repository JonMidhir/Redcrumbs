module Redcrumbs
 module Options
    extend ActiveSupport::Concern
    
    module ClassMethods
      # prepare_redcrumbed_options prepares class level options that customise the behaviour of
      # redcrumbed. See documentation for a full explanation of redcrumbed options.
      def prepare_redcrumbed_options(options)
        cattr_accessor :only, :store, :if, :unless
        
        defaults = {
          :only => [],
          :store => []
        }
        
        options.reverse_merge!(defaults)
        
        options[:only] = Array(options[:only])
        options[:store] = Array(options[:store])
        
        class_inheritable_accessor :redcrumbs_options
        self.redcrumbs_options = options.dup
        
        self.if = options[:if] unless options[:if]
        self.unless = options[:unless] unless options[:unless]
      end
    end
  end
end