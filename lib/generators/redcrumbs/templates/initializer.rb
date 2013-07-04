Redcrumbs.setup do |config|
  # When a change is made to a redcrumbed model the user associated with that model will
  # automatically be stored on the Crumb object. By default Redcrumbs will look for a User
  # object using 'id' as the primary key but you can override that here.
  #
  # config.creator_class_sym = :user
  # config.creator_primary_key = 'id'
  # config.target_class_sym = :user
  # config.target_primary_key = 'id'
  #
  #
  # If you're using the crumbs to report news back to a user you can store creator and target 
  # attributes on the crumb object to avoid having to touch your main database at all. Keep it 
  # sensible and evaluate whether the additional space used in Redis is really worth the time saving.
  #
  # config.store_creator_attributes = [:id, :name, :email]
  # config.store_target_attributes = [:id, :name, :email]
  #
  #
  # Set the mortality to make crumbs automatically expire in time. Default is infinity.
  # config.mortality = 30.days
end

# Point this to your redis connection. It can be a Redis object or a string.
Redcrumbs.redis = 'localhost:6379'

# You may want to create a config/redcrumbs.yml file and base your redis setting
# from that. e.g. (thanks to Resque for this):

# rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
# rails_env = ENV['RAILS_ENV'] || 'development'
# 
# redcrumbs_config = YAML.load_file(rails_root + '/config/redcrumbs.yml')
# Redcrumbs.redis = redcrumbs_config[rails_env]