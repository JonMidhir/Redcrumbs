require 'spec_helper.rb'

describe Redcrumbs::Creation do
  let(:name){ 'Paperboy' }
  let(:score){ 12934 }

  context "creation of crumbs from updates" do
    subject{ Game.create(:name => name, :highscore => score) }

    it 'should have one crumb for initial values' do
      expect(subject.crumbs.count).to eq(1)
    end

    it 'should create one crumb when single attribute changed' do
      expect {
        subject.update(:highscore => 12935)
      }.to change { subject.crumbs.count }.by(1)
    end

    it 'should create one crumb when multiple attributes changed' do
      expect {
        subject.update(:highscore => 12935, :name => 'Paperboy 2')
      }.to change { subject.crumbs.count }.by(1)
    end

    it 'should create multiple crumbs with multiple updates' do
      expect {
        subject.update(:highscore => 12935)
        subject.update(:name => 'Paperboy 2')
      }.to change { subject.crumbs.count }.by(2)
    end

    it 'should not create crumb when no tracked attributes changed' do
      expect {
        subject.update(:platform => 'Commodore 64')
      }.to change { subject.crumbs.count }.by(0)
    end
  end

  context "conditional creation based on attributes" do
    before do
      @default_options = Game.redcrumbs_options.dup
    end

    after do
      Game.prepare_redcrumbed_options(@default_options)
    end

    it 'should not create crumb if `if` unsatisfied' do
      Game.prepare_redcrumbed_options(:only => [:name], :if => :persisted?)

      game = Game.new(name: 'Paperperson')

      expect { game.save }.to change { game.crumbs.count }.by(0)
    end

    it 'should not create crumb if `unless` satisfied' do
      Game.prepare_redcrumbed_options(:only => [:name], :unless => :new_record?)

      game = Game.new(name: 'Paperperson')

      expect { game.save }.to change { game.crumbs.count }.by(0)
    end
  end

  context "a created crumb's attributes" do
    let(:creator) { User.create(:name => 'Jon Hope') }
    subject{ Game.create(:name => name, :highscore => score, :creator => creator) }

    before do
      puts subject.creator.inspect
      subject.update(:highscore => 15000, :platform => 'Amiga')
    end

    it 'restricts columns according to :only' do
      expect(subject.crumbs.last.modifications.keys).to eq(["highscore"])
    end

    it 'stores subject_id' do
      expect(subject.crumbs.last.subject_id).to eq(subject.id)
    end

    it 'stores subject class as subject_type' do
      expect(subject.crumbs.last.subject_type).to eq(subject.class.to_s)
    end

    it 'stores attributes of the subject according to :store' do
      expect(subject.crumbs.last.stored_subject.keys).to eq(["id", "name"])
    end

    it 'stores creator_id' do
      expect(subject.crumbs.last.creator_id).to eq(creator.id)
    end

    it 'stores target_id' do
      expect(subject.crumbs.last.target_id).to eq(creator.id)
    end
  end
end