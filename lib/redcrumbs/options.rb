module Redcrumbs
 module Options
    extend ActiveSupport::Concern
    
    module ClassMethods
      # prepare_redcrumbed_options prepares class level options that customise the behaviour of
      # redcrumbed. See documentation for a full explanation of redcrumbed options.
      def prepare_redcrumbed_options(options)
        defaults = {
          :only => [],
          :store => {}
        }
        
        options.reverse_merge!(defaults)
        
        options[:only] = Array(options[:only])
        options[:store] = options[:store]
        
        class_attribute :redcrumbs_options
        class_attribute :redcrumbs_callback_options
        
        self.redcrumbs_options = options.dup
        self.redcrumbs_callback_options = options.dup.select {|k,v| [:if, :unless].include?(k.to_sym)}
      end
    end
  end
end