module Redcrumbs
# Provides methods for giving user context to crumbs. Retrieves crumbs created by a user (creator) or
# affecting a user (target)
  module Users
    extend ActiveSupport::Concern

    # Retrieves crumbs related to the user
    #
    def crumbs_for(opts = {})
      klass = Redcrumbs.crumb_class

      klass.targetted_by(self).all(opts)
    end

    # Retrieves crumbs created by the user
    #
    def crumbs_by(opts = {})
      klass = Redcrumbs.crumb_class

      klass.created_by(self).all(opts)
    end

    # Or queries don't seem to be working with dm-redis-adapter. This
    # is a temporary workaround.
    #
    def crumbs_as_user(opts = {})
      opts[:limit] ||= 100

      arr = crumbs_by.to_a + crumbs_for.to_a
      arr.uniq!

      arr.sort_by! {|c| [c.created_at, c.id]}.reverse
    end

    # Creator method defines who should be considered the creator when a model is updated. This
    # can be overridden in the redcrumbed model to define who the creator should be. Defaults
    # to the current user (or creator class) associated with the model.
    def creator
      super
    rescue NoMethodError
      default_creator
    end

    private

    def default_creator
      send(Redcrumbs.creator_class_sym) if respond_to?(Redcrumbs.creator_class_sym)
    end
  end
end