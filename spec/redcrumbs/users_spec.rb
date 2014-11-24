require 'spec_helper.rb'

describe Redcrumbs::Users do
  let(:computer_player) { ComputerPlayer.create(:name => 'Jon Hope') }
  let(:player) { Player.create(:name => 'Jon Hope') }
  let(:game) { Game.create(:name => 'Paperboy', :highscore => 3943, :high_scorer => computer_player) }

  before do
    game.update_attributes(:name => 'Newspaper Delivery Person')
    game.update_attributes(:highscore => 4001, :high_scorer => player)
    @first_crumb, @second_crumb, @last_crumb = game.crumbs.to_a
  end

  # Getting crumbs by a user
  #
  it 'should recall crumbs created by a player' do
    crumbs = computer_player.crumbs_by(:order => [:created_at.desc, :id.desc])
    expect(crumbs).to eq([@second_crumb, @first_crumb])
  end

  # Getting crumbs targetting a user
  #
  it 'should retrieve crumbs created by others affecting this player' do
    crumbs = computer_player.crumbs_for(:order => [:created_at.desc, :id.desc])
    expect(crumbs).to eq([@last_crumb])
  end

  # Getting all crumbs affecting a user
  #
  it 'should retrieve all crumbs affecting a user' do
    crumbs = computer_player.crumbs_as_user(:order => [:created_at.desc, :id.desc])
    expect(crumbs).to eq([@last_crumb, @second_crumb, @first_crumb])
  end
end