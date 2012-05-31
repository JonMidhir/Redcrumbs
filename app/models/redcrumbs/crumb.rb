require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-redis-adapter'

## Note to self: Syntax to grab all by an attribute is - Notification.all(:subject_type => "User")
## The attribute must be indexed as with subject_type below

module Redcrumbs
  class Crumb
    REDIS = Redis.new
    
    include DataMapper::Resource
    include Crumb::Getters
    include Crumb::Setters
    include Crumb::Expiry
    
    DataMapper.setup(:default, {:adapter  => "redis"})
    
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
      if self.subject = params[:subject]
        self.target = self.subject.target if self.subject.respond_to?(:target)
        self.creator = self.subject.creator if self.subject.respond_to?(:creator)
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
    
    def redis_key
      "redcrumbs_crumbs:#{id}"
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      REDIS.keys("redcrumbs_crumbs:*").size - 8
    end
  end
end