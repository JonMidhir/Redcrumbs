Redcrumbs.setup do |config|
  config.creator_class_sym = :user
  config.creator_id = 'zid'
  config.target_class_sym = :user
  config.target_id = 'zid'
  
  # If you're using the notifications to report news back to a user you can store creator and target 
  # attributes on the notification object to avoid having to touch your main database at all. Keep it 
  # sensible and evaluate whether the additional space used in Redis is really worth the time saving.
  # e.g. config.store_creator_attributes = [:id, :name, :email]
  config.store_creator_attributes = [:zid, :gamername]
  config.store_target_attributes = [:zid, :gamername]
end