module Redcrumbs
  module Options
    extend ActiveSupport::Concern
    
    module InstanceMethods
      def creator_class
        Redcrumbs.creator_class
      end
    end
  end
end