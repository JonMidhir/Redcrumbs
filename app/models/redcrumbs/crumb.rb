require 'dm-core'
require 'dm-types'
require 'dm-redis-adapter'

## Note to self: Syntax to grab all by an attribute is - Notification.all(:subject_type => "User")
## The attribute must be indexed as with subject_type below

module Redcrumbs
  DataMapper.setup(:default, {:adapter  => "redis"})

  class Crumb
    include DataMapper::Resource

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

    attr_accessor :_subject, :_creator, :_target

    REDIS = Redis.new

    def initialize(params = {})
      self.target = params[:target] unless !params[:target]
      self.creator = params[:creator] unless !params[:creator]
      self.subject = params[:subject] unless !params[:subject]
      self.modifications = params[:modifications] unless !params[:modifications]
    end

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

    def subject=(subject)
      self.stored_subject = subject.storeable_attributes
      self.subject_type = subject.class.to_s
      self.subject_id = subject.id
    end

    def subject_from_storage
      new_subject = subject_type.constantize.new(self.stored_subject)
      new_subject.id = self.stored_subject["id"] if self.stored_subject.has_key?("id")
      new_subject
    end

    def creator
      if !self.stored_creator.blank?
        Redcrumbs.creator_class.new(self.stored_creator)
      elsif !self.creator_id.blank?
        self._user ||= full_creator
      end
    end

    def creator=(creator)
      self.stored_creator = creator.attributes.select {|attribute| Redcrumbs.store_creator_attributes.include?(attribute.to_sym)}
    end

    def full_creator
      Redcrumbs.creator_class.where(Redcrumbs.creator_id => self.creator_id).first
    end

    def target
      if !self.stored_target.blank?
        Redcrumbs.target_class.new(self.stored_target)
      elsif !self.target_id.blank?
        self._target ||= full_target
      end
    end

    def full_target
      Redcrumbs.target_class.where(Redcrumbs.target_id => self.creator_id).first
    end

    def target=(target)
      self.stored_target = target.attributes.select {|attribute| Redcrumbs.store_target_attributes.include?(attribute.to_sym)}
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
      self.creator_id = creator[Redcrumbs.creator_id] unless !creator
      self.target_id = target[Redcrumbs.target_id] unless !target
    end
  end
end