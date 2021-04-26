# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'class' do
  context 'when changes are not permitted' do
    permitted_risk = {
      'not-permitted' => false,
    }

    let(:facts) { { 'arbiter' => { 'permitted_risk' => permitted_risk } } }

    it { is_expected.to compile }
    it { is_expected.to contain_notify('1-should-be-noop').with_noop(true) }
  end
end
