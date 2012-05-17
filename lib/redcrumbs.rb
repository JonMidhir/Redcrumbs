require "redcrumbs/version"
require 'redcrumbs/engine'
require 'dm-core'

module Redcrumbs
  
  mattr_accessor :creator_class_sym
  mattr_accessor :creator_id
  mattr_accessor :target_class_sym
  mattr_accessor :target_id
  
  mattr_accessor :store_creator_attributes
  mattr_accessor :store_target_attributes
  
  def self.setup
    yield self
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def creator_class
    self.creator_class_sym.to_s.classify.constantize
  end
  
  def target_class
    self.target_class_sym.to_s.classify.constantize
  end
  
  module ClassMethods
    def redcrumbed(opts = {})
      
      cattr_accessor :fields, :store, :if, :unless
      
      self.fields = []
      self.store = []
      self.if = []
      self.unless = []
      self.fields += Array(opts[:only]) unless !opts[:only]
      self.store += Array(opts[:store]) unless !opts[:store]
      self.if += Array(opts[:if]) unless !opts[:if]
      self.unless += Array(opts[:unless]) unless !opts[:unless]
      
      around_save :notify_changes, :if => self.if, :unless => self.unless
      
      include Redcrumbs::InstanceMethods
    end
  end
  
  module InstanceMethods
    def crumbs_for
      Crumb.all(:target_id => self.zid, :order => [:created_at.desc])
    end
    
    def crumbs_by
      Crumb.all(:user_id => self.zid, :order => [:created_at.desc])
    end
    
    # This is an unforunate hack to get over the redis dm adapter's non-support of addition (OR) queries
    def crumbs_as_user(opts = {})
      opts[:limit] ||= 100
      arr = notifications_for 
      arr += notifications_by
      arr.all(:limit => opts[:limit])
    end
    
    def crumbs
      Crumb.all(:subject_type => self.class.to_s, :subject_id => self.zid)
    end
    
    def is?(conditionals)
      eval(conditionals)
    end
    
    def watched_changes
      changes.reject {|k,v| !self.class.fields.include?(k.to_sym)}
    end
    
    def storeable_attributes
      attributes.reject {|k,v| !self.class.store.include?(k.to_sym)}
    end
    
    def watched_changes_empty?
       watched_changes.empty?
    end
    
    def creator
      send(creator_class_sym) if respond_to?(creator_class_sym)
    end

    private

    def notify_changes
      unless watched_changes.empty?
        n = Crumb.build_from(self)
        n.save
      end
      yield
    end
  end
end
