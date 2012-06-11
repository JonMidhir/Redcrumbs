module Redcrumbs
  mattr_accessor :creator_class_sym
  mattr_accessor :creator_primary_key
  mattr_accessor :target_class_sym
  mattr_accessor :target_primary_key

  mattr_accessor :store_creator_attributes
  mattr_accessor :store_target_attributes

  mattr_accessor :mortality
  mattr_accessor :redis
  
  @@creator_class_sym ||= :user
  @@creator_primary_key ||= 'id'
  @@target_class_sym ||= :user
  @@target_primary_key ||= 'id'
  
  @@store_creator_attributes ||= []
  @@store_target_attributes ||= []
  
  # Stolen from resque. Thanks!
  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server, :thread_safe => true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= :redcrumbs

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(:redcrumbs, :redis => server)
    end
    @redis
  end
  
  def redis
    return @redis if @redis
    self.redis = Redis.respond_to?(:connect) ? Redis.connect : "localhost:6379"
    self.redis
  end
end