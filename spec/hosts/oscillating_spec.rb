# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'oscillating' do
  context 'when stacked scopes repeatedly change the change_risk()' do
    permitted_risk = {
      'not-permitted' => false,
      'permitted'     => true,
    }

    let(:facts) { { 'arbiter' => { 'permitted_risk' => permitted_risk } } }

    it { is_expected.to compile }
    it { is_expected.to contain_notify('1-should-be-op').without_noop }
    it { is_expected.to contain_notify('2-should-be-noop').with_noop(true) }
    it { is_expected.to contain_notify('3-should-be-op').without_noop }
    it { is_expected.to contain_notify('4-should-be-noop').with_noop(true) }
  end
end
