require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-redis-adapter'

## Note to self: Syntax to grab all by an attribute is - Notification.all(:subject_type => "User")
## The attribute must be indexed as with subject_type below

module Redcrumbs
  class Crumb
    
    include DataMapper::Resource
    
    DataMapper.setup(:default, {:adapter  => "redis", :host => Redcrumbs.redis.client.host, :port => Redcrumbs.redis.client.port, :password => Redcrumbs.redis.client.password})
    
    property :id, Serial
    property :subject_id, Integer, :index => true, :lazy => false
    property :subject_type, String, :index => true, :lazy => false
    property :modifications, Json, :default => "{}", :lazy => false
    property :created_at, DateTime
    property :updated_at, DateTime
    property :stored_creator, Json, :lazy => false
    property :stored_target, Json, :lazy => false
    property :stored_subject, Json, :lazy => false
    property :creator_id, Integer, :index => true
    property :target_id, Integer, :index => true

    DataMapper.finalize
    
    after :save, :set_mortality

    attr_accessor :_subject, :_creator, :_target

    def initialize(params = {})
      if params[:subject] && self.subject = params[:subject]
        self.target = self.full_subject.target if self.subject.respond_to?(:target)
        self.creator = self.full_subject.creator if self.subject.respond_to?(:creator)
      end

      self.modifications = params[:modifications] unless !params[:modifications]
    end

    def self.build_with_modifications(subject)
      unless subject.watched_changes.empty?
        params = {:modifications => subject.watched_changes}
        params.merge!({:subject => subject})
        new(params)
      end
    end
    
    def set_context_from(subject)
      self.subject = subject unless !!subject_id
      self.target ||= self.subject.target if self.subject.respond_to?(:target)
      self.creator ||= self.subject.creator if self.subject.respond_to?(:creator)
    end

    # Getters

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


    # Setters

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

    
    def redis_key
      "redcrumbs_crumbs:#{id}"
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      Redcrumbs.redis.keys("redcrumbs_crumbs:*").size - 8
    end


    # Expiry

    def mortal?
      !!Redcrumbs.mortality
    end

    def expire_at
      Time.now + Redcrumbs.mortality
    end
    
    def time_to_live
      Redcrumbs.redis.ttl(redis_key) if mortal?
    end
    
    private
    
    def set_mortality
      Redcrumbs.redis.expireat(redis_key, expire_at.to_i) if mortal?
    end
  end
end