# frozen_string_literal: true

require 'spec_helper'

describe 'risk-not-found' do
  permitted_risk = {
    'penguins' => true,
  }

  let(:facts) { { 'arbiter' => { 'permitted_risk' => permitted_risk } } }

  context 'risk_not_found_action=fail' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          risk_not_found_action => 'fail',
        }
      MANIFEST
    }

    it { is_expected.to compile.and_raise_error(/Permitted risk data unavailable/) }
  end

  context 'risk_not_found_action=none' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          risk_not_found_action => 'none',
        }
      MANIFEST
    }

    it { is_expected.to contain_notify('test').without_noop }
  end

  context 'risk_not_found_action=noop' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          risk_not_found_action => 'noop',
        }
      MANIFEST
    }

    it { is_expected.to contain_notify('test').with_noop(true) }
  end
end
