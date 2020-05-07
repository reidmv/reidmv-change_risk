# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'testnode' do
  context 'when all changes are permitted' do
    permitted_risk = {
      'test'             => true,
      'block'            => true,
      'inner'            => true,
      'block_inner_diff' => true,
    }

    let(:facts) do
      permitted_risk.reduce({}) { |memo,(k,v)| memo["permit_#{k}"] = v; memo }
    end

    it { is_expected.to compile }

    include_examples 'correct resource tagging'
    include_examples 'correct noop setting', permitted_risk: permitted_risk
  end

  context 'when no changes are permitted' do
    permitted_risk = {
      'test'             => false,
      'block'            => false,
      'inner'            => false,
      'block_inner_diff' => false,
    }

    let(:facts) do
      permitted_risk.reduce({}) { |memo,(k,v)| memo["permit_#{k}"] = v; memo }
    end

    it { is_expected.to compile }

    include_examples 'correct resource tagging'
    include_examples 'correct noop setting', permitted_risk: permitted_risk
  end
end
