module Redcrumbs
# Provides methods for giving user context to crumbs. Retrieves crumbs created by a user (creator) or
# affecting a user (target)
 module Users
    extend ActiveSupport::Concern
    
    module InstanceMethods
      # Retrieves crumbs related to the user
      def crumbs_for
        crumb_or_custom_class.all(:target_id => self[Redcrumbs.target_primary_key], :order => [:created_at.desc])
      end

      # Retrieves crumbs created by the user
      def crumbs_by
        crumb_or_custom_class.all(:creator_id => self[Redcrumbs.creator_primary_key], :order => [:created_at.desc])
      end
      
      # A limitable collection of both crumbs_for and crumbs_by
      # This is an unforunate hack to get over the redis dm adapter's non-support of addition (OR) queries
      def crumbs_as_user(opts = {})
        opts[:limit] ||= 100
        arr = crumbs_for 
        arr += crumbs_by
        arr.all(opts)
      end
      
      # Creator method defines who should be considered the creator when a model is updated. This
      # can be overridden in the redcrumbed model to define who the creator should be. Defaults
      # to the current user (or creator class) associated with the model.
      def creator
        send(Redcrumbs.creator_class_sym) if respond_to?(Redcrumbs.creator_class_sym)
      end
      
      private
      
      def crumb_or_custom_class
         if self.class.redcrumbs_options[:class_name]
           self.class.redcrumbs_options[:class_name].to_s.capitalize.constantize
         else
           Crumb
         end
      end
    end
  end
end