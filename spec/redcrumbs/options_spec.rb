require 'spec_helper'

describe Redcrumbs::Options do
  context 'with explicit configuration' do
    let(:options){ {'only' => [:id, :name], :store => {:only =>[:id, :name]}, :if => :new_record?, :unless => :persisted?} }
    
    before do
      @default_options = Game.redcrumbs_options.dup
      Game.prepare_redcrumbed_options(options)
    end

    after do
      Game.prepare_redcrumbed_options(@default_options)
    end

    it 'has symbolized keys' do
      expect(Game.redcrumbs_options.keys).to all(be_a(Symbol))
    end

    it 'has symbolized keys for callback options' do
      expect(Game.redcrumbs_callback_options.keys).to eq([:if, :unless])
    end

    it 'has symbolized callback method name for :if option' do
      expect(Game.redcrumbs_callback_options[:if]).to eq(:new_record?)
    end

    it 'has symbolized callback method name for :unless option' do
      expect(Game.redcrumbs_callback_options[:unless]).to eq(:persisted?)
    end

    it 'has ignored options that are not valid callback conditionals' do
      expect(Game.redcrumbs_callback_options[:store]).to be_nil
    end
  end

  context 'default configuration options' do
    before do
      @default_options = Game.redcrumbs_options.dup
      Game.prepare_redcrumbed_options({})
    end

    after do
      Game.prepare_redcrumbed_options(@default_options)
    end

    subject { Game.redcrumbs_options.dup }

    it 'defaults to empty array for only' do
      expect(subject[:only]).to eq([])
    end

    it 'defaults to empty hash for store' do
      expect(subject[:store]).to eq({})
    end

    it 'defaults to nil for if' do
      expect(subject[:if]).to be_nil
    end

    it 'defaults to nil for unless' do
      expect(subject[:unless]).to be_nil
    end
  end
end