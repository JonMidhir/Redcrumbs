require 'spec_helper'

describe Redcrumbs::Options do
  describe '.redcrumbs_callback_options' do
    context 'with empty configuration' do
      let!(:default_options) { Game.redcrumbs_options.dup }

      before { Game.prepare_redcrumbed_options({}) }
      after  { Game.prepare_redcrumbed_options(default_options) }

      subject { Game.redcrumbs_callback_options }

      it { is_expected.not_to have_key(:if) }
      it { is_expected.not_to have_key(:unless) }
    end

    context 'with explicit configuration' do
      let!(:options){ {:store => {:only =>[:id, :name]}, :if => :new_record?, :unless => :persisted?} }
      let!(:default_options) { Game.redcrumbs_options.dup }

      before { Game.prepare_redcrumbed_options(options) }
      after  { Game.prepare_redcrumbed_options(default_options) }

      subject { Game.redcrumbs_callback_options }

      it { is_expected.to have_key(:if) }
      it { is_expected.to have_key(:unless) }
      it { is_expected.not_to have_key(:store) }

      it { is_expected.to include(:if => :new_record?) }
      it { is_expected.to include(:unless => :persisted?) }
    end
  end


  describe '.redcrumbs_options' do
    context 'with empty configuration' do
      let!(:default_options) { Game.redcrumbs_options.dup }

      before { Game.prepare_redcrumbed_options({}) }
      after  { Game.prepare_redcrumbed_options(default_options) }

      subject { Game.redcrumbs_options }

      it { is_expected.to have_key(:only) }
      it { is_expected.to have_key(:store) }

      it { is_expected.to include(:only => []) }
      it { is_expected.to include(:store => {}) }
    end

    context 'with explicit configuration' do
      let!(:options){ {'only' => [:id, :name], :store => {:only => [:name]}} }
      let!(:default_options) { Game.redcrumbs_options.dup }

      before { Game.prepare_redcrumbed_options(options) }
      after  { Game.prepare_redcrumbed_options(default_options) }

      subject { Game.redcrumbs_options }

      it { is_expected.to have_key(:only) }
      it { is_expected.to have_key(:store) }

      it { is_expected.not_to have_key('only')}

      it { is_expected.to include(:only => [:id, :name]) }
      it { is_expected.to include(:store => {:only => [:name]}) }
    end
  end
end