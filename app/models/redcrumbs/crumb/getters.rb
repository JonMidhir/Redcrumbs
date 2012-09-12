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
      self._subject ||= subject_type.classify.constantize.find(subject_id)
    end
    
    def subject_from_storage
      new_subject = subject_type.constantize.new(self.stored_subject)
      new_subject.id = self.stored_subject["id"] if self.stored_subject.has_key?("id")
      new_subject
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
      self._creator ||= creator_class.new(self.stored_creator.reject {|attribute| [:id].include?(attribute.to_sym)})
      self._creator.id ||= self.stored_creator["id"] if self._creator.has_attribute?(:id) && self.stored_creator.has_key?("id")
      self._creator
    end
    
    def full_creator
      self._creator = creator_class.where(Redcrumbs.creator_primary_key => self.creator_id).first
    end
    
    def target
      if !self.stored_target.blank?
        initialize_target_from_hash_of_attributes
      elsif !self.target_id.blank?
        full_target
      end
    end
    
    def initialize_target_from_hash_of_attributes
      self._target ||= target_class.new(self.stored_target.reject {|attribute| [:id].include?(attribute.to_sym)})
      self._target.id ||= self.stored_target["id"] if self._target.has_attribute?(:id) && self.stored_target.has_key?("id")
      self._target
    end
    
    def target_class
      self._target ||= Redcrumbs.target_class_sym.to_s.classify.constantize
    end

    def full_target
      target_class.where(Redcrumbs.target_primary_key => self.target_id).first
    end
  end
end