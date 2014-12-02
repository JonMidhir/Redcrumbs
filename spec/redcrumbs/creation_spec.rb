require 'spec_helper.rb'

describe Redcrumbs::Creation do
  let(:name){ 'Paperboy' }
  let(:score){ 12934 }

  describe 'model' do
    subject { Game.create(:name => name, :highscore => score) }

    context 'when created' do
      it { expect(subject.crumbs.count).to eq(1) }
    end

    context 'when single tracked attribute updated' do
      it do 
        expect {
          subject.update_attributes(:highscore => 12935) 
        }.to change { subject.crumbs.count }.by(1)
      end
    end

    context 'when multiple tracked attributes updated' do
      it do 
        expect {
          subject.update_attributes(:highscore => 12935, :name => 'Paperboy 2') 
        }.to change { subject.crumbs.count }.by(1)
      end
    end

    context 'when updated twice' do
      it do 
        expect {
          subject.update_attributes(:highscore => 12935)
          subject.update_attributes(:name => 'Paperboy 2')
        }.to change { subject.crumbs.count }.by(2)
      end
    end

    context 'when untracked attribute updated' do
      it do 
        expect {
          subject.update_attributes(:platform => 'Commodore 64')
        }.to change { subject.crumbs.count }.by(0)
      end
    end
  end


  describe 'conditional creation' do
    before { @default_options = Game.redcrumbs_options.dup }
    after  { Game.redcrumbed(@default_options) }

    context 'when `if` condition unsatisfied' do
      before  { Game.redcrumbed(:only => [:name], :if => :new_record?) }
      subject { Game.new(name: name) }

      it { expect { subject.save }.to change { subject.crumbs.count }.by(0) }
    end

    context 'when `unless` condition satisfied' do
      before  { Game.redcrumbed(:only => [:name], :unless => :persisted?) }
      subject { Game.new(name: name) }

      it { expect { subject.save }.to change { subject.crumbs.count }.by(0) }
    end
  end


  describe "a created crumb's attributes" do
    let(:computer_player) { ComputerPlayer.create(:name => 'Ramsey') }
    let(:player) { Player.create(:name => 'Jon Hope') }

    let(:game) { Game.create(:name => name, :highscore => score, :high_scorer => computer_player) }

    before { game.update_attributes(:highscore => 15000, :platform => 'Amiga', :high_scorer => player) }

    subject { game.crumbs.last }

    it { is_expected.to have_attributes(:modifications => { 'highscore' => [12934, 15000] }) }
    it { is_expected.to have_attributes(:subject_id => game.id) }
    it { is_expected.to have_attributes(:subject_type => game.class.name) }
    it { is_expected.to have_attributes(:creator_id => player.id) }
    it { is_expected.to have_attributes(:creator_type => player.class.name) }
    it { is_expected.to have_attributes(:target_id => computer_player.id) }
    it { is_expected.to have_attributes(:target_type => computer_player.class.name) }
  end


  describe '#watched_changes' do
    let(:game) { Game.create(:name => name, :highscore => score) }
    subject { game.watched_changes }

    context 'when changes made' do
      before { game.assign_attributes(:name => 'Papergal', :platform => 'C64')}

      it { is_expected.to include(:name) }
      it { is_expected.not_to include(:platform) }
    end

    context 'when no changes made' do
      it { is_expected.to eq({}) }
    end
  end


  describe '#storable_attributes_keys' do
    let!(:default_options) { Game.redcrumbs_options[:store].dup }
    after { Game.redcrumbs_options[:store] = default_options}
    subject { Game.new.storable_attributes_keys }

    context 'when `only` set' do
      before { Game.redcrumbs_options[:store] = {only: [:name]} }

      it { is_expected.to eq([:name]) }
    end

    context 'when `except` set' do
      before { Game.redcrumbs_options[:store] = {except: [:name]} }

      it { is_expected.to include(:id, :created_at, :updated_at) }
      it { is_expected.not_to include(:name) }
    end

    context 'when `only` and `except` set' do
      before { Game.redcrumbs_options[:store] = {except: [:name], only: [:id]}}

      it { is_expected.to eq([:id]) }
    end

    context 'when neither `only` or `except` set' do
      before { Game.redcrumbs_options[:store] = {} }

      it { is_expected.to eq([]) }
    end
  end


  describe '#storeable_attributes' do
    let!(:default_options) { Game.redcrumbs_options[:store].dup }
    after { Game.redcrumbs_options[:store] = default_options}
    subject { Game.new(name: name).storeable_attributes }

    context 'when `only` set' do
      before { Game.redcrumbs_options[:store] = {only: [:name]} }

      it { is_expected.to eq({'name' => name}) }
    end

    context 'when `except` set' do
      before { Game.redcrumbs_options[:store] = {except: [:name]} }

      it { is_expected.to include('id', 'created_at', 'updated_at') }
      it { is_expected.not_to include('name') }
    end

    context 'when `only` and `except` set' do
      before { Game.redcrumbs_options[:store] = {except: [:name], only: [:id]}}

      it { is_expected.to eq('id' => nil) }
    end

    context 'when neither `only` or `except` set' do
      before { Game.redcrumbs_options[:store] = {} }

      it { is_expected.to eq({}) }
    end
  end


  describe '#storable_methods_names' do
    let!(:default_options) { Game.redcrumbs_options[:store].dup }
    after { Game.redcrumbs_options[:store] = default_options}
    subject { Game.new.storable_methods_names }

    context 'when `methods` set' do
      before { Game.redcrumbs_options[:store] = {methods: [:persisted?]} }

      it { is_expected.to eq([:persisted?]) }
    end

    context 'when `methods` not set' do
      before { Game.redcrumbs_options[:store] = {} }

      it { is_expected.to eq([]) }
    end
  end


  describe '#storable_methods' do
    let!(:default_options) { Game.redcrumbs_options[:store].dup }
    after { Game.redcrumbs_options[:store] = default_options}
    subject { Game.new.storable_methods }

    context 'when `methods` set' do
      before { Game.redcrumbs_options[:store] = {methods: [:persisted?]} }

      it { is_expected.to include('persisted?') }
    end

    context 'when `methods` not set' do
      before { Game.redcrumbs_options[:store] = {} }

      it { is_expected.to eq({}) }
    end
  end


  describe '#serialized_as_redcrumbs_subject' do
    let!(:default_options) { Game.redcrumbs_options[:store].dup }
    after { Game.redcrumbs_options[:store] = default_options}
    subject { Game.new(name: name).serialized_as_redcrumbs_subject }

    context 'when `store` set' do
      before { Game.redcrumbs_options[:store] = {only: [:name]} }

      it { is_expected.to eq({'name' => name}) }
    end

    context 'when `methods` set' do
      before { Game.redcrumbs_options[:store] = {methods: [:persisted?]} }

      it { is_expected.to eq({'persisted?' => false}) }
    end

    context 'when `store` and `methods` set' do
      before { Game.redcrumbs_options[:store] = {only: [:name], methods: [:persisted?]} }

      it { is_expected.to eq({'name' => name, 'persisted?' => false}) }
    end

    context 'when neither `store` or `methods` set' do
      before { Game.redcrumbs_options[:store] = {} }

      it { is_expected.to eq({}) }
    end
  end


  describe '#create_crumb' do
    let(:game) { Game.new(:name => name, :platform => 'C64') }
    let(:crumb) { game.create_crumb }

    context 'with created crumb' do
      subject { crumb }
      it { is_expected.to have_attributes(:subject => game)}
      it { is_expected.to respond_to(:modifications)}
    end

    context 'with created crumb modifications' do
      subject { crumb.modifications }

      it { is_expected.to include(:name) }
      it { is_expected.not_to include(:platform) }
    end
  end


  describe '#notify_changes' do
    let(:game) { Game.create(:name => name, :platform => 'C64') }

    context 'without watched_changes' do
      it { expect { game.notify_changes }.to change { game.crumbs.count }.by(0) }
    end

    context 'with watched_changes' do
      before { game.name = 'Paperperson' }

      it { expect { game.notify_changes }.to change { game.crumbs.count }.by(1) }
    end
  end
end