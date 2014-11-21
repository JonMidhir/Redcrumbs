require 'spec_helper.rb'

describe Redcrumbs::Crumb do
  def user
    @user ||= User.create(:name => 'Jon Hope')
  end

  let(:game) do 
    Game.create(:name => 'Paperboy', :highscore => 3943, :creator => user)
  end

  before do
    game.update_attributes(:name => 'Newspaper Delivery Person')
    game.update_attributes(:highscore => 4001)
    @first_crumb, @second_crumb, @last_crumb = game.crumbs.to_a
  end

  it 'defaults to ordering by number when finding through association' do
    expect(@first_crumb.modifications).to eq({'name' => [nil, 'Paperboy'], 'highscore' => [nil, 3943]})
    expect(@second_crumb.modifications).to eq({'name' => ['Paperboy', 'Newspaper Delivery Person']})
    expect(@last_crumb.modifications).to eq({'highscore' => [3943, 4001]})
  end

  it 'returns the stored subject' do
    expect(@first_crumb.subject.id).to eq(game.id)
    expect(@first_crumb.subject.name).to eq('Paperboy')
    expect(@first_crumb.subject.highscore).to eq(nil)
  end

  it 'returns the full subject' do
    expect(@first_crumb.full_subject.id).to eq(game.id)
    expect(@first_crumb.full_subject.name).to eq('Newspaper Delivery Person')
    expect(@first_crumb.full_subject.highscore).to eq(4001)
  end

  it 'returns the creator' do
    expect(@first_crumb.creator).to eq(user)
    expect(@second_crumb.creator).to eq(user)
    expect(@last_crumb.creator).to eq(user)
  end

  it 'initializes with modifications' do
    crumb = Redcrumbs::Crumb.new(modifications: {'name' => [nil, 'Paperboy']})

    expect(crumb.modifications).to eq({'name' => [nil, 'Paperboy']})
  end

  it 'initializes with subject' do
    crumb = Redcrumbs::Crumb.new(subject: game)

    expect(crumb.subject).to be(game)
  end

  it 'initializes from changed object' do
    game.name = 'News Distribution Expert'

    crumb = Redcrumbs::Crumb.build_with_modifications(game)

    expect(crumb.modifications).to eq({'name' => ['Newspaper Delivery Person', 'News Distribution Expert']})
  end

  it 'assigns and returns subject_type' do
    crumb = Redcrumbs::Crumb.new(subject: game)

    expect(crumb.subject_type).to eq(game.class.to_s)
  end

  it 'assigns and returns subject_id' do
    crumb = Redcrumbs::Crumb.new(subject: game)

    expect(crumb.subject_id).to eq(game.id)
  end

  it 'returns the correct redis_key' do
    crumb    = Redcrumbs::Crumb.new(subject: game)
    crumb.id = 4

    expect(crumb.redis_key).to eq('redcrumbs_crumbs:4')
  end

  # Mortality
  context 'With mortality set globally' do
    before do
      Redcrumbs.mortality = 30.days

      game.update_attributes(name: 'News Distribution Expert')
      @crumb = game.crumbs.last
    end

    after do
      Redcrumbs.mortality = nil
    end

    it 'sets the mortality according to global setting' do
      expect(@crumb.mortal?).to eq(true)
    end

    it 'returns the correct ttl' do
      expect(@crumb.time_to_live).to be_truthy
    end

    it 'returns the correct expires_at' do
      expect(@crumb.expires_at.to_i).to eq((Time.now + @crumb.time_to_live).to_i)
    end
  end
end