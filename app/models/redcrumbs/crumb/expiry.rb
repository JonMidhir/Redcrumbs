module Redcrumbs
  module Crumb::Expiry
    extend ActiveSupport::Concern
    
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
  end
end