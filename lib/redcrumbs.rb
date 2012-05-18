require 'active_support/concern'
require 'active_support/dependencies/autoload'
require "redcrumbs/version"
require 'redcrumbs/engine'
require 'dm-core'

# Redcrumbs implements dirty models to track changes to ActiveRecord models in a way that is fast and
# unobtrusive. By storing the data in Redis instead of a SQL database the footprint is greatly reduced, no
# schema changes are necessary and we can harness all the advantages of a key value store; such as key expiry.
#
# Author:: John Hope
# Copyright:: Copyright (c) 2012 John Hope for Project Zebra
# License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
#
# To start tracking a model use the 'redcrumbed' method:
#
#   class Venue
#     redcrumbed, :only => [:name, :latlng]
#   end
#
#   venue = Venue.last
#   venue.crumbs(:limit => 20)
#   crumb = venue.crumbs.last
#   crumb.creator
#      => #<User ... >
#   crumb.modifications
#      => {"name"=>["Belfast City Hall", "The City Hall, Belfast"]}
#
# See the documentation for more details on how to customise and use Redcrumbs.

module Redcrumbs
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload
  
  autoload :Options
  autoload :Config
  
  include Config
  
  def self.setup
    yield self
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def redcrumbed(options = {})
      include Options
      
      prepare_redcrumbed_options(options)
      
      around_save :notify_changes #, :if => options[:if], :unless => options[:unless]
      
      include Redcrumbs::InstanceMethods
    end
  end
  
  module InstanceMethods
    def crumbs_for
      Crumb.all(:target_id => self[Redcrumbs.target_primary_key], :order => [:created_at.desc])
    end
    
    def crumbs_by
      Crumb.all(:creator_id => self[Redcrumbs.creator_primary_key], :order => [:created_at.desc])
    end
    
    # This is an unforunate hack to get over the redis dm adapter's non-support of addition (OR) queries
    def crumbs_as_user(opts = {})
      opts[:limit] ||= 100
      arr = crumbs_for 
      arr += crumbs_by
      arr.all(:limit => opts[:limit])
    end
    
    def crumbs
      Crumb.all(:subject_type => self.class.to_s, :subject_id => self.id)
    end
    
    def watched_changes
      changes.reject {|k,v| !self.class.redcrumbs_options[:only].include?(k.to_sym)}
    end
    
    def storeable_attributes
      attributes.reject {|k,v| !self.class.redcrumbs_options[:store].include?(k.to_sym)}
    end
    
    def watched_changes_empty?
       watched_changes.empty?
    end
    
    # You can override this is method in your own models to define who the creator should be.
    def creator
      send(Redcrumbs.creator_class_sym) if respond_to?(Redcrumbs.creator_class_sym)
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

ActiveRecord::Base.class_eval { include Redcrumbs }