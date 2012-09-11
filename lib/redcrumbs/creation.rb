module Redcrumbs
  module Creation
    extend ActiveSupport::Concern
    
    module InstanceMethods
      def crumbs
        Crumb.all(:subject_type => self.class.to_s, :subject_id => self.id)
      end

      def watched_changes
        changes.slice(*self.class.redcrumbs_options[:only])
      end

      def storeable_attributes
        store = self.class.redcrumbs_options[:store]
        if store.has_key?(:only)
          attributes.reject {|k,v| !store[:only].include?(k.to_sym)}
        elsif store.has_key?(:except)
          attributes.reject {|k,v| store[:except].include?(k.to_sym)}
        else
          {}
        end
      end
      
      def attributes_from_storeable_methods
        store = self.class.redcrumbs_options[:store]
        if store.has_key?(:methods)
          # get the methods that actually exist on the model
          methods = methods_from_array(store[:methods])
          # inject them into a hash with their outcomes as values
          methods.inject({}) {|h,a| h.merge(a => send(a))}
        else
          {}
        end
      end
      
      def storeable_attributes_and_method_attributes
        storeable_attributes.merge(attributes_from_storeable_methods)
      end
      
      def create_crumb
        n = Crumb.build_with_modifications(self)
        n.save
      end
      
      # This is called after the record is saved to store the changes on the model, including anything done in before_save validations
      def notify_changes
        create_crumb unless watched_changes.empty?
      end
      
      private
      
      def methods_from_array(array)
        self.class.instance_methods.select {|method| array.include?(method.to_sym)}
      end
    end
  end
end