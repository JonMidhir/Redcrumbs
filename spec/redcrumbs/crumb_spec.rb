require 'spec_helper.rb'

describe Redcrumbs::Crumb do
  let(:player) { Player.create(:name => 'Jon Hope') }
  let(:player_2) { Player.create(:name => 'Ash Dwyer') }
  let(:game) { Game.create(:name => 'Paperboy', :highscore => 4001) }

  describe '.build_with_modifications' do
    context 'when subject has no changes' do
      subject { Redcrumbs::Crumb.build_with_modifications(game) }

      it { is_expected.to be_nil }
    end

    context 'when subject has no watched changes' do
      before  { game.platform = 'Spectrum'}
      subject { Redcrumbs::Crumb.build_with_modifications(game) }

      it { is_expected.to be_nil }
    end

    context 'when subject has changes' do
      before { game.assign_attributes(:highscore => 19000, :name => 'Papergal') }

      subject { Redcrumbs::Crumb.build_with_modifications(game).modifications }

      it { is_expected.not_to eq({}) }
      it { is_expected.to include('highscore' => [4001, 19000]) }
      it { is_expected.to include('name' => ['Paperboy', 'Papergal']) }
    end
  end


  describe 'subject' do
    let(:crumb) { game.crumbs.last }

    context 'when instantiating a stored subject' do
      subject! { crumb.subject }

      it { is_expected.to be_present }
      it { expect(subject.id).to eq(game.id) }
      it { expect(subject.name).to eq(game.name) }
      it { expect(subject.highscore).to be_nil }
      it { expect(crumb.named_association('subject')).not_to be_loaded }
    end

    context 'when retrieving a full subject' do
      subject! { crumb.full_subject }

      it { is_expected.to be_present }
      it { is_expected.to eq(game) }
      it { expect(subject.highscore).to eq(game.highscore) }
      it { expect(crumb.named_association('subject')).to be_loaded }
    end
  end


  describe 'creator' do
    let!(:default_options) { Redcrumbs.store_creator_attributes.dup }
    let(:crumb) { game.crumbs.last } 

    before do
      Redcrumbs.store_creator_attributes = [:name]
      game.update_attributes(:highscore => 20000, :high_scorer => player)
    end

    after  { Redcrumbs.store_creator_attributes = default_options }

    context 'when nil' do
      subject(:creator) { game.crumbs.first.creator }

      it { is_expected.not_to be_present }
    end

    context 'when instantiating from storage' do
      subject!(:creator) { crumb.creator }

      it { is_expected.to be_present }
      it { expect(creator.id).to eq(player.id) }
      it { expect(creator.name).to eq(player.name) }
      it { expect(creator.created_at).to be_nil }
      it { expect(crumb.named_association('creator')).not_to be_loaded }
    end

    context 'when retrieving a full creator' do
      subject!(:creator) { crumb.full_creator }

      it { is_expected.to be_present }
      it { is_expected.to eq(player) }
      it { expect(creator.created_at.to_i).to eq(player.created_at.to_i) }
      it { expect(crumb.named_association('creator')).to be_loaded }
    end
  end


  describe 'target' do
    let!(:default_options) { Redcrumbs.store_target_attributes.dup }
    let(:crumb) { game.crumbs.last } 

    before do
      Redcrumbs.store_target_attributes = [:name]
      game.update_attributes(:highscore => 19890, :high_scorer => player)
      game.update_attributes(:highscore => 20000, :high_scorer => player_2)
    end

    after  { Redcrumbs.store_target_attributes = default_options }

    context 'when nil' do
      subject(:target) { game.crumbs.first.target }

      it { is_expected.not_to be_present }
    end

    context 'when instantiating from storage' do
      subject!(:target) { crumb.target }

      it { is_expected.to be_present }
      it { expect(target.id).to eq(player.id) }
      it { expect(target.name).to eq(player.name) }
      it { expect(target.created_at).to be_nil }
      it { expect(crumb.named_association('target')).not_to be_loaded }
    end

    context 'when retrieving a full target' do
      subject!(:target) { crumb.full_target }

      it { is_expected.to be_present }
      it { is_expected.to eq(player) }
      it { expect(target.created_at.to_i).to eq(player.created_at.to_i) }
      it { expect(crumb.named_association('target')).to be_loaded }
    end
  end


  describe '.initialize' do
    context 'with modifications' do
      subject { Redcrumbs::Crumb.new(modifications: {'name' => [nil, 'Paperboy']}).modifications }

      it { is_expected.not_to eq({}) }
      it { is_expected.to include('name' => [nil, 'Paperboy']) }
    end

    context 'with subject' do
      subject { Redcrumbs::Crumb.new(subject: game) }

      it { is_expected.to have_attributes(:subject => game) }
      it { is_expected.to have_attributes(:subject_id => game.id) }
      it { is_expected.to have_attributes(:subject_type => game.class.name) }
    end
  end


  describe '#redis_key' do
    let!(:crumb) { Redcrumbs::Crumb.new(subject: game) }

    context 'when new' do
      subject { crumb.redis_key }

      it { is_expected.to be_nil }
    end

    context 'when persisted' do
      before  { crumb.save }
      subject { crumb.redis_key }

      it { is_expected.to eq("redcrumbs_crumbs:#{crumb.id}")}
    end
  end


  describe '#mortal?' do
    let!(:default_value) { Redcrumbs.mortality }

    context 'when unpersisted' do
      subject { Redcrumbs::Crumb.new(subject: game).mortal? }

      it { is_expected.to be_falsey }
    end

    context 'when mortal' do
      before  { Redcrumbs.mortality = 30.days }
      after   { Redcrumbs.mortality = default_value }
      subject { Redcrumbs::Crumb.create(subject: game).mortal? }

      it { is_expected.to be_truthy }
    end

    context 'when immortal' do
      before  { Redcrumbs.mortality = nil }
      after   { Redcrumbs.mortality = default_value }
      subject { Redcrumbs::Crumb.create.mortal? }

      it { is_expected.to be_falsey }
    end
  end


  describe '#time_to_live' do
    let!(:default_value) { Redcrumbs.mortality }

    context 'when unpersisted' do
      subject { Redcrumbs::Crumb.new(subject: game).time_to_live }

      it { is_expected.to be_nil }
    end

    context 'when immortal' do
      before  { Redcrumbs.mortality = nil }
      after   { Redcrumbs.mortality = default_value }
      subject { Redcrumbs::Crumb.create(subject: game).time_to_live }

      it { is_expected.to eq(-1) }
    end

    context 'when mortal' do
      before  { Redcrumbs.mortality = 30.days }
      after   { Redcrumbs.mortality = default_value }
      subject { Redcrumbs::Crumb.create(subject: game) }

      it { expect(subject.time_to_live).to be_truthy }
      it { expect(subject.time_to_live).to be_within(2.seconds.to_i).of(30.days.to_i) }
    end
  end


  describe '#expires_at' do
    let!(:default_value) { Redcrumbs.mortality }

    context 'when unpersisted' do
      let(:crumb) { Redcrumbs::Crumb.new }
      subject { crumb.expires_at }

      it { is_expected.to be_nil }
    end

    context 'when mortal' do
      before  { Redcrumbs.mortality = 30.days }
      after   { Redcrumbs.mortality = default_value }
      let(:crumb) { Redcrumbs::Crumb.create }
      subject { crumb.expires_at.to_i }

      it { is_expected.to be_truthy }
      it { is_expected.to eq((Time.now + crumb.time_to_live).to_i) }
    end

    context 'when immortal' do
      before  { Redcrumbs.mortality = nil }
      after   { Redcrumbs.mortality = default_value }
      subject { Redcrumbs::Crumb.new.expires_at }

      it { is_expected.to be_nil }
    end
  end
end