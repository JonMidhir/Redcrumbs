require 'spec_helper'

describe Redcrumbs do
  describe '.creator_class_sym' do
    subject { Redcrumbs.creator_class_sym }

    context 'when unchanged' do
      it { is_expected.to eq(:user) }
    end

    context 'when changed to :game' do
      before { Redcrumbs.creator_class_sym = :game }
      after  { Redcrumbs.creator_class_sym = :user }

      it { is_expected.to eq(:game)}
    end
  end


  describe '.creator_primary_key' do
    subject { Redcrumbs.creator_primary_key }

    context 'when unchanged' do
      it { is_expected.to be_nil }
    end

    context 'when changed to :name' do
      before { Redcrumbs.creator_primary_key = :name }
      after  { Redcrumbs.creator_primary_key = :id }

      it { is_expected.to eq(:name)}
    end
  end


  describe '.target_class_sym' do
    subject { Redcrumbs.target_class_sym }

    context 'when unchanged' do
      it { is_expected.to eq(:user) }
    end

    context 'when changed to :game' do
      before { Redcrumbs.target_class_sym = :game }
      after  { Redcrumbs.target_class_sym = :user }

      it { is_expected.to eq(:game)}
    end
  end


  describe '.target_primary_key' do
    subject { Redcrumbs.target_primary_key }

    context 'when unchanged' do
      it { is_expected.to be_nil }
    end

    context 'when changed to :name' do
      before { Redcrumbs.target_primary_key = :name }
      after  { Redcrumbs.target_primary_key = :id }

      it { is_expected.to eq(:name)}
    end
  end


  describe '.store_creator_attributes' do
    subject { Redcrumbs.store_creator_attributes }

    context 'when unchanged' do
      it { is_expected.to eq([]) }
    end

    context 'when given attribute keys' do
      before { Redcrumbs.store_creator_attributes = [:id, :name] }
      after  { Redcrumbs.store_creator_attributes = [] }

      it { is_expected.to eq([:id, :name])}
    end
  end


  describe '.store_target_attributes' do
    subject { Redcrumbs.store_target_attributes }

    context 'when unchanged' do
      it { is_expected.to eq([]) }
    end

    context 'when given attribute keys' do
      before { Redcrumbs.store_target_attributes = [:id, :name] }
      after  { Redcrumbs.store_target_attributes = [] }

      it { is_expected.to eq([:id, :name])}
    end
  end


  describe '.redis' do
    let!(:default_redis) { Redcrumbs.redis }
    subject { Redcrumbs.redis }

    context 'when given a URL string with port and scheme' do
      before { Redcrumbs.redis = 'redis://localhost:6379' }
      after { Redcrumbs.redis = default_redis }

      it { expect(subject.namespace).to eq(:redcrumbs) }
      it { expect(subject.client.host).to eq('localhost') }
      it { expect(subject.client.port).to eq(6379) }
    end

    context 'when given a URL string without scheme' do
      before { Redcrumbs.redis = 'localhost:6379' }
      after { Redcrumbs.redis = default_redis }

      it { expect(subject.namespace).to eq(:redcrumbs) }
      it { expect(subject.client.host).to eq('localhost') }
      it { expect(subject.client.port).to eq(6379) }
    end

    context 'when given a URL string with namespace' do
      before { Redcrumbs.redis = 'localhost:6379/some_namespace' }
      after { Redcrumbs.redis = default_redis }

      it { expect(subject.namespace).to eq('some_namespace') }
    end

    context 'when given an existing redis client' do
      let(:redis) { Redis.new }
      before { Redcrumbs.redis = redis }
      after { Redcrumbs.redis = default_redis }

      it { expect(subject.redis).to eq(redis) }
    end

    context 'when given an existing redis namespace' do
      let(:redis) { Redis::Namespace.new('some_namespace') }
      before { Redcrumbs.redis = redis }
      after { Redcrumbs.redis = default_redis }

      it { is_expected.to eq(redis) }
    end
  end


  describe '.crumb_class' do
    subject { Redcrumbs.crumb_class }

    context 'when class_name unchanged' do
      it { is_expected.to be(Redcrumbs::Crumb) }
    end

    context 'when class_name set to unknown class' do
      before { Redcrumbs.class_name = :foo }
      after  { Redcrumbs.class_name = nil }

      it { is_expected.to be(Redcrumbs::Crumb) }
    end

    context 'when class doesnt inherit from Crumb' do
      before { Redcrumbs.class_name = :game }
      after  { Redcrumbs.class_name = nil }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end