require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-redis-adapter'
require 'redcrumbs/serializable_association'

module Redcrumbs
  class Crumb
    
    include DataMapper::Resource
    include Redcrumbs::SerializableAssociation

    DataMapper.setup(:default, {:adapter  => "redis", :host => Redcrumbs.redis.client.host, :port => Redcrumbs.redis.client.port, :password => Redcrumbs.redis.client.password})
    
    property :id, Serial
    property :subject_id, Integer, :index => true, :lazy => false
    property :subject_type, String, :index => true, :lazy => false
    property :stored_subject, Json, :lazy => false
    property :modifications, Json, :default => "{}", :lazy => false
    property :created_at, DateTime
    property :updated_at, DateTime

    DataMapper.finalize
    
    after :save, :set_mortality

    serializable_association(:creator)
    serializable_association(:target)

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

    def redis_key
      "redcrumbs_crumbs:#{id}"
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      Redcrumbs.redis.keys("redcrumbs_crumbs:*").size - 8
    end

    # Expiry

    def mortal?
      !!time_to_live
    end
    
    def time_to_live
      @ttl ||= Redcrumbs.redis.ttl(redis_key)
    end

    def expires_at
      Time.now + time_to_live
    end
    
    private
    
    def set_mortality
      Redcrumbs.redis.expireat(redis_key, expire_from_now.to_i) if Redcrumbs.mortality
    end

    def expire_from_now
      Time.now + Redcrumbs.mortality
    end
  end
end