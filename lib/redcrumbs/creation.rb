module Redcrumbs
  module Creation
    extend ActiveSupport::Concern

    module ClassMethods
      def deserialize_from_redcrumbs(attributes = {})
        clean_attrs = attributes.select {|k,v| column_names.include?(k.to_s)}
        new(clean_attrs, :without_protection => true)
      end
    end
    
    def crumbs
      Crumb.all(:subject_type => self.class.to_s, :subject_id => self.id)
    end

    def watched_changes
      changes.slice(*self.class.redcrumbs_options[:only])
    end

    def storable_attributes_keys
      store = self.class.redcrumbs_options[:store]
      
      store[:only] or 
      (store[:except] and attributes.keys.reject {|key| store[:except].include?(key.to_sym)}) or
      []
    end

    def storeable_attributes
      attributes.slice *storable_attributes_keys.map(&:to_s)
    end

    def storable_methods_names
      store = self.class.redcrumbs_options[:store]

      if store[:methods]
        methods.select {|method| store[:methods].include?(method.to_sym)}
      else
        []
      end
    end
    
    def storable_methods
      storable_methods_names.inject({}) {|h, n| h.merge(n => send(n))}
    end
    
    def serialized_as_redcrumbs_subject
      storeable_attributes.merge(storable_methods)
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