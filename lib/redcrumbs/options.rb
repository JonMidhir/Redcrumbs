module Redcrumbs
 module Options
    extend ActiveSupport::Concern
    
    module ClassMethods
      # prepare_redcrumbed_options prepares class level options that customise the behaviour of
      # redcrumbed. See documentation for a full explanation of redcrumbed options.
      def prepare_redcrumbed_options(options)
        options.symbolize_keys!

        defaults = {
          :only => [],
          :store => {}
        }
        
        options.reverse_merge!(defaults)
        
        options[:only] = Array(options[:only])
        
        class_attribute :redcrumbs_options
        
        self.redcrumbs_options = options.dup

        options
      end

      def redcrumbs_callback_options
        redcrumbs_options.slice(:if, :unless)
      end
    end
  end
end