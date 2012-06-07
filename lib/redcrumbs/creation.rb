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
        attributes.reject {|k,v| !self.class.redcrumbs_options[:store].include?(k.to_sym)}
      end
      
      def create_crumb
        n = Crumb.build_with_modifications(self)
        n.save
      end
      
      # This is called after the record is saved to store the changes on the model, including anything done in before_save validations
      def notify_changes
        create_crumb unless watched_changes.empty?
      end
    end
  end
end