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

    def initialize(params = {})
      self.subject = params[:subject]
      self.modifications = params[:modifications]
    end

    def self.build_with_modifications(subject)
      return if subject.watched_changes.empty?

      new(:modifications => subject.watched_changes, :subject => subject)
    end

    def subject=(subject)
      return nil unless subject

      @subject = subject
      self.stored_subject = subject.storeable_attributes_and_method_attributes
      self.subject_type = subject.class.to_s
      self.subject_id = subject.id

      self.target  = subject.target  if subject.respond_to?(:target)
      self.creator = subject.creator if subject.respond_to?(:creator)

      subject
    end

    def subject
      if self.stored_subject.present?
        load_subject_from_storage
      elsif subject_type and subject_id
        full_subject
      end
    end

    def full_subject
      if @subject.blank? or @subject.new_record?
        @subject = subject_type.classify.constantize.find(subject_id)
      else
        @subject
      end
    end
    
    def load_subject_from_storage
      @subject ||= subject_type.constantize.new(self.stored_subject, :without_protection => true)
    end

    def creator=(creator)
      return unless creator

      @creator = creator
      self.stored_creator = creator.attributes.select {|attribute| Redcrumbs.store_creator_attributes.include?(attribute.to_sym)}
      self.creator_id = creator[Redcrumbs.creator_primary_key]
    end
    
    def creator
      if self.stored_creator.present?
        load_creator_from_storage
      elsif self.creator_id.present?
        full_creator
      end
    end
    
    def creator_class
      Redcrumbs.creator_class_sym.to_s.classify.constantize
    end
    
    def load_creator_from_storage
      @creator ||= creator_class.new(self.stored_creator, :without_protection => true)
    end
    
    # grabbing full creator/target should memoize the result. Check to see is it a new_record (i.e. from storage) first
    def full_creator
      if @creator.blank? or @creator.new_record?
        @creator = creator_class.where(Redcrumbs.creator_primary_key => self.creator_id).first
      else
        @creator
      end
    end

    def target=(target)
      return unless target

      @target = target
      self.stored_target = target.attributes.select {|attribute| Redcrumbs.store_target_attributes.include?(attribute.to_sym)}
      self.target_id = target[Redcrumbs.target_primary_key]
    end
    
    def target
      if self.stored_target.present?
        load_target_from_storage
      elsif self.target_id.present?
        full_target
      end
    end
    
    def load_target_from_storage
      @target ||= target_class.new(self.stored_target, :without_protection => true)
    end
    
    def target_class
      Redcrumbs.target_class_sym.to_s.classify.constantize
    end

    def full_target
      if @target.blank? or @target.new_record?
        @target = target_class.where(Redcrumbs.target_primary_key => self.target_id).first
      else
        @target
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