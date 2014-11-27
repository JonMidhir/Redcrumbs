require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-redis-adapter'
require 'redcrumbs/serializable_association'

module Redcrumbs
  class Crumb
    
    include DataMapper::Resource
    include Redcrumbs::SerializableAssociation
    
    property :id, Serial
    property :modifications, Json, :default => "{}", :lazy => false
    property :created_at, DateTime
    property :updated_at, DateTime

    DataMapper.finalize

    after :save, :set_mortality

    serializable_association :creator
    serializable_association :target
    serializable_association :subject

    def initialize(params = {})
      self.subject = params[:subject]
      self.modifications = params[:modifications]
    end

    def self.build_with_modifications(subject)
      return if subject.watched_changes.empty?

      new(:modifications => subject.watched_changes, :subject => subject)
    end

    def self.created_by(creator)
      all(:creator_id => creator[Redcrumbs.creator_primary_key]) &
      all(:creator_type => creator.class.name)
    end

    def self.targetted_by(target)
      all(:target_id => target[Redcrumbs.target_primary_key]) &
      all(:target_type => target.class.name)
    end

    # Overrides the subject setter created by the SerializableAttributes
    # module.
    #
    def subject=(subject)
      @subject = subject

      self.stored_subject = subject ? serialize(:subject, subject) : {}
      self.subject_id = subject ? subject.id : nil
      assign_type_for(:subject, subject)

      self.target  = subject.target  if subject.respond_to?(:target)
      self.creator = subject.creator if subject.respond_to?(:creator)

      subject
    end

    def redis_key
      "redcrumbs_crumbs:#{id}" if id
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      Redcrumbs.redis.keys("redcrumbs_crumbs:*").size - 8
    end

    # Expiry

    def mortal?
      return false if new?

      time_to_live >= 0
    end
    
    def time_to_live
      return nil if new?

      @ttl ||= Redcrumbs.redis.ttl(redis_key)
    end

    def expires_at
      Time.now + time_to_live if time_to_live
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