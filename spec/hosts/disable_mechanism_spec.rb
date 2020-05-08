# frozen_string_literal: true

require 'spec_helper'

describe 'disable-mechanism' do
  let(:facts) {
    { 'arbiter' => { 'permitted_risk' => { 'test' => false } } }
  }

  context 'disable_mechanism=flag' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          disable_mechanism => 'flag',
        }
      MANIFEST
    }

    describe '--no-noop flag passed' do
      let (:facts) { super().merge({'noop_cli_value' => false}) }
      it { is_expected.to contain_notify('test').without_noop }
    end

    describe 'flag not passed' do
      it { is_expected.to contain_notify('test').with_noop(true) }
    end
  end

  context 'disable_mechanism=fact' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          disable_mechanism => 'fact',
        }
      MANIFEST
    }

    describe 'ignore_permitted_risk fact set' do
      let (:facts) { super().merge({'ignore_permitted_risk' => true}) }
      it { is_expected.to contain_notify('test').without_noop }
    end

    describe 'ignore_permitted_risk fact not set' do
      it { is_expected.to contain_notify('test').with_noop(true) }
    end
  end
end
