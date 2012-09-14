module Redcrumbs
  module Crumb::Getters
    extend ActiveSupport::Concern
    
    def subject
      if !self.stored_subject.blank?
        subject_from_storage
      elsif subject_type && subject_id
        full_subject
      end
    end

    def full_subject
      if self._subject.blank? || self._subject.new_record?
        self._subject = subject_type.classify.constantize.find(subject_id)
      else
        self._subject
      end
    end
    
    def subject_from_storage
      self._subject ||= subject_type.constantize.new(self.stored_subject, :without_protection => true)
    end
    
    def creator
      if !self.stored_creator.blank?
        initialize_creator_from_hash_of_attributes
      elsif !self.creator_id.blank?
        full_creator
      end
    end
    
    def creator_class
      Redcrumbs.creator_class_sym.to_s.classify.constantize
    end
    
    def initialize_creator_from_hash_of_attributes
      self._creator ||= creator_class.new(self.stored_creator, :without_protection => true)
    end
    
    # grabbing full creator/target should cache the result. Check to see is it a new_record (i.e. from storage) first
    def full_creator 
      if self._creator.blank? || self._creator.new_record?
        self._creator = creator_class.where(Redcrumbs.creator_primary_key => self.creator_id).first
      else
        self._creator
      end
    end
    
    def target
      if !self.stored_target.blank?
        initialize_target_from_hash_of_attributes
      elsif !self.target_id.blank?
        full_target
      end
    end
    
    def initialize_target_from_hash_of_attributes
      self._target ||= target_class.new(self.stored_target, :without_protection => true)
    end
    
    def target_class
      self._target ||= Redcrumbs.target_class_sym.to_s.classify.constantize
    end

    def full_target
      if self._target.blank? || self._target.new_record?
        self._target = target_class.where(Redcrumbs.target_primary_key => self.target_id).first
      else
        self._target
      end
    end
  end
end