module Redcrumbs
  module Crumb::Setters
    extend ActiveSupport::Concern
    
    def subject=(subject)
      self._subject = subject
      self.stored_subject = subject.storeable_attributes_and_method_attributes
      self.subject_type = subject.class.to_s
      self.subject_id = subject.id
    end

    def creator=(creator)
      unless !creator
        self._creator = creator
        self.stored_creator = creator.attributes.select {|attribute| Redcrumbs.store_creator_attributes.include?(attribute.to_sym)}
        self.creator_id = creator[Redcrumbs.creator_primary_key]
      end
    end

    def target=(target)
      unless !target
        self._target = target
        self.stored_target = target.attributes.select {|attribute| Redcrumbs.store_target_attributes.include?(attribute.to_sym)}
        self.target_id = target[Redcrumbs.target_primary_key]
      end
    end
  end
end