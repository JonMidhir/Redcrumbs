require 'spec_helper.rb'

describe Redcrumbs::Users do
  let(:computer_player) { ComputerPlayer.create(:name => 'Jon Hope') }
  let(:player) { Player.create(:name => 'Jon Hope') }

  let!(:crumb_1) do 
    c = Redcrumbs::Crumb.new
    c.creator = computer_player
    c.save
    c
  end

  let!(:crumb_2) do 
    c = Redcrumbs::Crumb.new
    c.creator = computer_player
    c.save
    c
  end

  let!(:crumb_3) do 
    c = Redcrumbs::Crumb.new
    c.creator = player
    c.target  = computer_player
    c.save
    c
  end


  describe '.crumbs_by' do
    context 'when in reverse order' do
      subject { computer_player.crumbs_by(:order => [:created_at.desc, :id.desc]) }

      it { is_expected.to eq([crumb_2, crumb_1])}
    end
  end


  describe '.crumbs_for' do
    context 'when in reverse order' do
      subject { computer_player.crumbs_for(:order => [:created_at.desc, :id.desc]) }

      it { is_expected.to eq([crumb_3]) }
    end
  end


  describe '.crumbs_as_user' do
    context 'when in reverse order' do
      subject { computer_player.crumbs_as_user(:order => [:created_at.desc, :id.desc]) }

      it { is_expected.to eq([crumb_3, crumb_2, crumb_1]) }
    end
  end
end