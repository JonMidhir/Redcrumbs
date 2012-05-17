require 'dm-core'
require 'dm-types'
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
    property :subject_id, Integer, :index => true
    property :subject_type, String, :index => true
    property :modifications, Json, :default => "{}"
    property :created_at, DateTime
    property :updated_at, DateTime
    property :stored_creator, Json
    property :stored_target, Json
    property :stored_subject, Json
    property :creator_id, Integer, :index => true
    property :target_id, Integer, :index => true

    DataMapper.finalize

    before :save, :convert_user_target_ids
    after :save, :set_mortality

    attr_accessor :_subject, :_creator, :_target

    def initialize(params = {})
      self.target = params[:target] unless !params[:target]
      self.creator = params[:creator] unless !params[:creator]
      self.subject = params[:subject] unless !params[:subject]
      self.modifications = params[:modifications] unless !params[:modifications]
    end

    # Remember to change the respond_to? argument when moving from user/target class to dynamic with user as default
    def self.build_from(subject)
      unless subject.watched_changes.empty?
        params = {:modifications => subject.watched_changes}
        params.merge!({:subject => subject})
        params.merge!({:target => subject.target}) if subject.respond_to?(:target)
        params.merge!({:creator => subject.creator})
        new(params)
      end
    end
    
    def redis_key
      "redcrumbs_crumbs:#{id}"
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      REDIS.keys("redcrumbs_crumbs:*").size - 8
      #REDIS.scard("redcrumbs_crumbs:id:all") << # not suitable. Still counts expired records
    end

    private

    def convert_user_target_ids
      self.creator_id = creator[creator_id] unless !creator
      self.target_id = target[target_id] unless !target
    end
  end
end