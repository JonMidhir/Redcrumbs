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
    
    def creator
      if !self.stored_creator.blank?
        creator_class.new(self.stored_creator)
      elsif !self.creator_id.blank?
        self._user ||= full_creator
      end
    end
    
    def full_creator
      creator_class.where(creator_primary_key => self.creator_id).first
    end

    def target
      if !self.stored_target.blank?
        target_class.new(self.stored_target)
      elsif !self.target_id.blank?
        self._target ||= full_target
      end
    end

    def full_target
      target_class.where(target_primary_key => self.creator_id).first
    end
  end
end