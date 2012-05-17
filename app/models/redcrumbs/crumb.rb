require 'dm-core'
require 'dm-types'
require 'dm-redis-adapter'

## Note to self: Syntax to grab all by an attribute is - Notification.all(:subject_type => "User")
## The attribute must be indexed as with subject_type below

module Redcrumbs
  DataMapper.setup(:default, {:adapter  => "redis"})

  class Crumb
    include DataMapper::Resource
    include Crumb::Properties
    include Crumb::Getters
    include Crumb::Setters

    before :save, :convert_user_target_ids

    attr_accessor :_subject, :_creator, :_target

    REDIS = Redis.new

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

    def deletable?
      if !!user_zid && !!target_zid
        checked? && checked_by_user_at > 3.days.ago && checked_by_target_at > 3.days.ago
      elsif !!user_zid
        checked? && checked_by_user_at > 3.days.ago
      else
        created_at > 14.days.ago
      end
    end

    def expire_at
      !!redis_deletable? ? Time.now + 3.days : self.created_at + 14.days
    end

    # Designed to mimic ActiveRecord's count. Probably not performant and only should be used for tests really
    def self.count
      REDIS.scard("redcrumbs_crumbs:id:all")
    end

    private

    def convert_user_target_ids
      self.creator_id = creator[creator_id] unless !creator
      self.target_id = target[target_id] unless !target
    end
  end
end