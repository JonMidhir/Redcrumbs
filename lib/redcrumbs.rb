require 'active_support'
require 'active_support/core_ext'
require 'active_support/concern'
require 'active_support/dependencies/autoload'
require 'active_record'
require 'redcrumbs/version'
require 'redcrumbs/config'
require 'redis'
require 'redis-namespace'
require 'dm-core'

# Redcrumbs uses `dirty attributes` to track and store changes to ActiveRecord models in a way that is fast and
# unobtrusive. By storing the data in Redis instead of a SQL database the footprint is greatly reduced, no
# schema changes are necessary and we can harness all the advantages of a key value store; such as key expiry.
#
# Author:: John Hope
# Copyright:: Copyright (c) 2014 John Hope for Project Zebra
# License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
#
# To start tracking a model use the 'redcrumbed' method:
#
#   class Venue
#     redcrumbed, :only => [:name, :latlng]
#
#     has_one :creator, :class_name => 'User'
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
  autoload :Users
  autoload :Creation
  autoload :Crumb

  include Options
  include Users

  def self.setup
    yield self
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def redcrumbed(options = {})
      include Creation

      prepare_redcrumbed_options(options)

      after_save :notify_changes, self.redcrumbs_callback_options

    end
  end
end

ActiveRecord::Base.class_eval { include Redcrumbs }