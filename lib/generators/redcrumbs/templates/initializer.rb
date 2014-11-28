Redcrumbs.setup do |config|
  # If your activity feeds are user-based you can store creator and target 
  # attributes on the crumb object to avoid having to touch your main database
  # at all. Keep it sensible and evaluate whether the additional space used in 
  # Redis is really worth the time saving. 
  # Note: You don't need to store the object id, it is already stored.
  #
  # config.store_creator_attributes = [:name, :email]
  # config.store_target_attributes = [:name, :email]
  #
  #
  # Set the mortality to make crumbs automatically expire in time. Default is infinity.
  # config.mortality = 30.days
end

# Point this to your redis connection. It can be a Redis client, namespace or a URL string.
Redcrumbs.redis = 'localhost:6379'