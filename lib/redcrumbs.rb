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
  autoload :Users
  autoload :Creation
  
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
      include Users
      include Creation
      
      prepare_redcrumbed_options(options)
      
      after_save :notify_changes, self.redcrumbs_callback_options

    end
  end
end

ActiveRecord::Base.class_eval { include Redcrumbs }