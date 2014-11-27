require 'spec_helper.rb'

describe Redcrumbs::SerializableAssociation do

  subject do 
    class Foo
      include Redcrumbs::SerializableAssociation
    end
  end

  context "inclusion of module" do
    it 'should define a public load_associated method' do
      expect(subject.new).to respond_to(:load_associated).with(1).arguments
    end
  end

  context "building an association" do
    it 'should raise error unless target, creator or subject' do
      expect { subject.serializable_association(:bar) }.to raise_error(ArgumentError)
    end
  end

  # Analogous for target and subject also
  #
  context "building a creator association" do
    before do 
      subject.serializable_association :creator
    end

    let(:new_foo) { subject.new }

    it "should add polymorphic creator properties" do
      expect(new_foo).to respond_to(:creator_id, :creator_id=, :creator_type, :creator_type=)
    end

    it "should add stored_creator Json property" do
      expect(new_foo).to respond_to(:stored_creator, :stored_creator=)
    end

    it 'should define a creator getter' do
      expect(new_foo).to respond_to(:creator)
    end

    it 'should define a creator setter' do
      expect(new_foo).to respond_to(:creator=).with(1).arguments
    end

    it 'should define a creator loader' do
      expect(new_foo).to respond_to(:full_creator)
    end
  end

  context "serializing an object" do
    let(:player) { Player.create(:name => "John Hope") }
    let(:game) { Game.create(:name => 'Paperboy', :highscore => 0)}
    let(:new_foo) { subject.new }

    before do
      Redcrumbs.store_creator_attributes = [:id, :name]
    end

    it 'should store the correct creator attributes' do
      serialized = new_foo.send('serialize', :creator, player)
      expect(serialized).to eq(player.attributes.slice('id', 'name'))
    end

    it 'should store the correct subject attributes' do
      serialized = new_foo.send('serialize', :subject, game)
      expect(serialized).to eq(game.attributes.slice('id', 'name'))
    end
  end

  context "deserializing an object" do
    let(:player) { Player.create(:name => "John Hope") }
    let(:game) { Game.create(:name => 'Paperboy', :highscore => 0)}

    before do
      subject.serializable_association :creator
    end

    let(:new_foo) { subject.new }

    it 'should return nil if no stored attributes' do
      deserialized = new_foo.send('deserialize', :creator)
      expect(deserialized).to be(nil)
    end

    it 'should initialize from stored creator attributes' do
      new_foo.creator_type = player.class.name
      new_foo.stored_creator = {id: player.id, name: player.name}
      new_foo.creator_id = player.id

      deserialized = new_foo.send('deserialize', :creator)
      expect(deserialized).to have_attributes(id: player.id, name: player.name)
    end

    # In the latest Redcrumbs the creator type will always be stored on the Crumb,
    # in previous versions it was loaded from the config so will be nil.
    #
    it 'should use config creator_class_sym option to initialize creator when not specified' do
      Redcrumbs.creator_class_sym = :player

      new_foo.stored_creator = {name: player.name}
      new_foo.creator_id = player.id

      deserialized = new_foo.send('deserialize', :creator)
      expect(deserialized).to have_attributes(id: player.id, name: player.name)
      Redcrumbs.creator_class_sym = :user
    end
  end
end