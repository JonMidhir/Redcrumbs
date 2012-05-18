module Redcrumbs
  module Crumb::Setters
    extend ActiveSupport::Concern
    
    def subject=(subject)
      self.stored_subject = subject.storeable_attributes
      self.subject_type = subject.class.to_s
      self.subject_id = subject.id
    end

    def creator=(creator)
      self.stored_creator = creator.attributes.select {|attribute| store_creator_attributes.include?(attribute.to_sym)}
    end

    def target=(target)
      self.stored_target = target.attributes.select {|attribute| store_target_attributes.include?(attribute.to_sym)}
    end
  end
end