module Redcrumbs
  module Crumb::Expiry
    extend ActiveSupport::Concern
    
    def mortal?
      !!Redcrumbs.mortality
    end

    def expire_at
      Time.now + Redcrumbs.mortality
    end
    
    def time_to_live
      REDIS.ttl(redis_key) if mortal?
    end
    
    private
    
    def set_mortality
      REDIS.expireat(redis_key, expire_at.to_i) if mortal?
    end
  end
end