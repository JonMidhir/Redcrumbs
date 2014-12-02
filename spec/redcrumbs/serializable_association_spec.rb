require 'spec_helper.rb'

describe Redcrumbs::SerializableAssociation do
  let(:foo) { Class.new { include Redcrumbs::SerializableAssociation } }

  describe '.serializable_association' do
    context 'when including module' do
      subject { foo.new }
      it { expect(foo).to respond_to(:serializable_association).with(1).argument }
    end

    context 'when given a valid association' do
      subject { foo.new }
      before  { foo.serializable_association(:creator) }

      it { expect(foo.serializable_association(:creator)).to be_truthy }
      it { is_expected.to respond_to(:creator_id).with(0).arguments }
      it { is_expected.to respond_to(:creator_type).with(0).arguments }
      it { is_expected.to respond_to(:stored_creator).with(0).arguments }
      it { is_expected.to respond_to(:creator).with(0).arguments }
      it { is_expected.to respond_to(:full_creator).with(0).arguments }
    end

    context 'when given an invalid association' do
      subject { foo.new }
      it { expect {foo.serializable_association(:bar)}.to raise_error(ArgumentError) }
    end
  end

  context "inclusion of module" do
    it 'should define a public named_association method' do
      expect(foo.new).to respond_to(:named_association).with(1).arguments
    end
  end


  describe '#serialize' do
    let(:player) { Player.create(:name => "John Hope") }
    let(:game) { Game.create(:name => 'Paperboy', :highscore => 0)}
    let(:new_foo) { foo.new }

    before { Redcrumbs.store_creator_attributes = [:id, :name] }

    context 'when serializing subject' do
      subject { new_foo.send('serialize', :subject, game) }
      it { is_expected.to eq(game.attributes.slice('id', 'name')) }
    end

    context 'when serializing creator' do
      subject { new_foo.send('serialize', :creator, player) }
      it { is_expected.to eq(player.attributes.slice('id', 'name')) }
    end
  end


  describe '#deserialize' do
    let(:player) { Player.create(:name => "John Hope") }
    let(:new_foo) { foo.new }

    before { foo.serializable_association :creator }

    context 'with no stored attributes' do
      subject { new_foo.send('deserialize', :creator) }

      it { is_expected.to be_nil }
    end

    context 'with stored attributes' do
      before do
        new_foo.send(:creator_type=, player.class.name)
        new_foo.send(:stored_creator=, {id: player.id, name: player.name})
        new_foo.send(:creator_id=, player.id)
      end

      subject { new_foo.send('deserialize', :creator) }

      it { is_expected.to have_attributes(id: player.id) }
      it { is_expected.to have_attributes(name: player.name) }
    end

    context 'when creator_type nil' do
      before do 
        Redcrumbs.creator_class_sym = :player

        new_foo.send(:stored_creator=, { name: player.name })
        new_foo.send(:creator_id=, player.id)
      end

      after  { Redcrumbs.creator_class_sym = :user }

      subject { new_foo.send('deserialize', :creator) }

      it { is_expected.to have_attributes(name: player.name) }
    end
  end
end