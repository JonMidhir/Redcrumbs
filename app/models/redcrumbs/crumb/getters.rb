module Redcrumbs
  module Crumb::Getters
    extend ActiveSupport::Concern
    
    def subject
      if !self.stored_subject.blank?
        subject_from_storage
      elsif subject_type && subject_id
        self._subject ||= full_subject
      end
    end

    def full_subject
      subject_type.classify.constantize.find(subject_id)
    end
    
    def subject_from_storage
      new_subject = subject_type.constantize.new(self.stored_subject)
      new_subject.id = self.stored_subject["id"] if self.stored_subject.has_key?("id")
      new_subject
    end
    
    def creator_class
      Redcrumbs.creator_class_sym.to_s.classify.constantize
    end
    
    def full_creator
      creator_class.where(Redcrumbs.creator_primary_key => self.creator_id).first
    end
    
    def target_class
      Redcrumbs.target_class_sym.to_s.classify.constantize
    end

    def full_target
      target_class.where(Redcrumbs.target_primary_key => self.creator_id).first
    end
  end
end