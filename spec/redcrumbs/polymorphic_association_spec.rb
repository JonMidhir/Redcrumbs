require 'spec_helper.rb'

describe Redcrumbs::SerializableAssociation::PolymorphicAssociation do
  let(:game) { Game.create(:name => 'Paperboy') }

  context 'without configuration' do
    it { is_expected.to have_attributes(:id => nil) }
    it { is_expected.to have_attributes(:class_name => nil) }
    it { is_expected.not_to be_loaded }
    it { is_expected.not_to be_loadable }
  end

  describe '.new' do
    subject { Redcrumbs::SerializableAssociation::PolymorphicAssociation.new(game.class.name, game.id) }

    context 'when not loaded' do
      it { is_expected.to have_attributes(:id => game.id) }
      it { is_expected.to have_attributes(:class_name => 'Game') }
      it { is_expected.not_to be_loaded }
      it { is_expected.to be_loadable }
    end

    context 'when loaded' do
      before { subject.load }

      it { is_expected.to be_loaded }
      it { is_expected.to have_attributes(:reflection => game) }
    end
  end

  describe '.with' do
    context 'with null argument' do
      subject { Redcrumbs::SerializableAssociation::PolymorphicAssociation.with(nil) }
      
      it { is_expected.to have_attributes(:id => nil) }
      it { is_expected.to have_attributes(:class_name => nil) }
      it { is_expected.to have_attributes(:reflection => nil) }
      it { is_expected.not_to be_loaded }
      it { is_expected.not_to be_loadable }
    end

    context 'with non-null argument' do
      subject { Redcrumbs::SerializableAssociation::PolymorphicAssociation.with(game) }

      it { is_expected.to have_attributes(:id => game.id) }
      it { is_expected.to have_attributes(:class_name => 'Game') }
      it { is_expected.to have_attributes(:reflection => game) }
      it { is_expected.to be_loaded }
      it { is_expected.to be_loadable }
    end
  end
end