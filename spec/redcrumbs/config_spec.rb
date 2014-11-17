require 'spec_helper'

describe Redcrumbs do
  context 'default module configuration options' do
    it 'defaults to :user for creator_class_sym' do
      expect(Redcrumbs.creator_class_sym).to eq(:user)
    end

    it 'defaults to id for creator_primary_key' do
      expect(Redcrumbs.creator_primary_key).to eq('id')
    end

    it 'defaults to :user for target_class_sym' do
      expect(Redcrumbs.target_class_sym).to eq(:user)
    end

    it 'defaults to id for target_primary_key' do
      expect(Redcrumbs.target_primary_key).to eq('id')
    end

    it 'defaults to empty array for store_creator_attributes' do
      expect(Redcrumbs.store_creator_attributes).to eq([])
    end

    it 'defaults to empty array for store_target_attributes' do
      expect(Redcrumbs.store_target_attributes).to eq([])
    end
  end

  context 'customised module configuration options' do
    before do
      Redcrumbs.setup do |config|
        config.creator_class_sym = :game
        config.creator_primary_key = :id
        config.target_class_sym = :game
        config.target_primary_key = :id
        config.store_creator_attributes = [:id, :name]
        config.store_target_attributes = [:id, :name]
      end
    end

    after do
      Redcrumbs.setup do |config|
        config.creator_class_sym = :user
        config.creator_primary_key = :id
        config.target_class_sym = :user
        config.target_primary_key = :id
        config.store_creator_attributes = []
        config.store_target_attributes = []
      end
    end

    it 'defaults to :user for creator_class_sym' do
      expect(Redcrumbs.creator_class_sym).to eq(:game)
    end

    it 'defaults to id for creator_primary_key' do
      expect(Redcrumbs.creator_primary_key).to eq(:id)
    end

    it 'defaults to :user for target_class_sym' do
      expect(Redcrumbs.target_class_sym).to eq(:game)
    end

    it 'defaults to id for target_primary_key' do
      expect(Redcrumbs.target_primary_key).to eq(:id)
    end

    it 'defaults to empty array for store_creator_attributes' do
      expect(Redcrumbs.store_creator_attributes).to eq([:id, :name])
    end

    it 'defaults to empty array for store_target_attributes' do
      expect(Redcrumbs.store_target_attributes).to eq([:id, :name])
    end

    it 'initializes redis client from URL string' do
      Redcrumbs.redis = 'redis://localhost:6379'
      expect(Redcrumbs.redis.namespace).to eq(:redcrumbs)
      expect(Redcrumbs.redis.client.host).to eq('localhost')
      expect(Redcrumbs.redis.client.port).to eq(6379)
    end

    it 'initializes redis client from URL string without scheme' do
      Redcrumbs.redis = 'localhost:6379'
      expect(Redcrumbs.redis.namespace).to eq(:redcrumbs)
      expect(Redcrumbs.redis.client.host).to eq('localhost')
      expect(Redcrumbs.redis.client.port).to eq(6379)
    end

    it 'initializes redis client from URL string with namespace' do
      Redcrumbs.redis = 'localhost:6379/some_namespace'

      expect(Redcrumbs.redis.namespace).to eq('some_namespace')
    end

    it 'uses existing redis client when assigned' do
      redis = Redis.new
      Redcrumbs.redis = redis

      expect(Redcrumbs.redis.redis).to be(redis)
    end

    it 'uses existing client namespace when assigned' do
      redis = Redis::Namespace.new('some_namespace')
      Redcrumbs.redis = redis
      
      expect(Redcrumbs.redis).to be(redis)
    end
  end
end