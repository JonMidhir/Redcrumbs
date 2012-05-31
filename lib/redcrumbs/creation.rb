module Redcrumbs
  module Creation
    extend ActiveSupport::Concern
    
    module InstanceMethods
      def crumbs
        Crumb.all(:subject_type => self.class.to_s, :subject_id => self.id)
      end

      def watched_changes
        changes.reject {|k,v| !self.class.redcrumbs_options[:only].include?(k.to_sym)}
      end

      def storeable_attributes
        attributes.reject {|k,v| !self.class.redcrumbs_options[:store].include?(k.to_sym)}
      end

      def watched_changes_empty?
        watched_changes.empty?
      end

      def notify_changes
        n = Crumb.build_with_modifications(self) unless watched_changes.empty?
        yield
        n.set_context_from(self) unless !n
        n.save unless !n
      end
    end
  end
end