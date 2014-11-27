module Redcrumbs
  module Creation
    extend ActiveSupport::Concern
    
    def crumbs
      Redcrumbs.crumb_class.all(
        :subject_type => self.class.to_s, 
        :subject_id => self.id
      )
    end

    def watched_changes
      changes.slice(*self.class.redcrumbs_options[:only])
    end

    def storable_attributes_keys
      store = self.class.redcrumbs_options[:store]
      
      store[:only] or 
      symbolized_attribute_keys(store[:except]) or
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
    
    # Todo: Fix inconsistent naming; storable vs storeable
    def storable_methods
      storable_methods_names.inject({}) {|h, n| h.merge(n.to_s => send(n))}
    end
    
    def serialized_as_redcrumbs_subject
      storeable_attributes.merge(storable_methods)
    end
    
    def create_crumb
      n = Redcrumbs.crumb_class.build_with_modifications(self)
      n.save
      n
    end
    
    # This is called after the record is saved to store the changes on the model, including anything done in before_save validations
    def notify_changes
      create_crumb unless watched_changes.empty?
    end
    
    private

    def symbolized_attribute_keys(except = [])
      return nil unless except

      symbolized_attribute_keys = attributes.dup.symbolize_keys!.keys
      symbolized_attribute_keys.reject {|key| except.include?(key)}
    end
    
    def methods_from_array(array)
      self.class.instance_methods.select {|method| array.include?(method.to_sym)}
    end
  end
end