# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples'

describe 'scoping' do
  context 'when evaluating a block' do
    let(:facts) { { 'hiera_path' => 'hash-type' } }

    it 'has access to parent-scope variables' do
      is_expected.to contain_notify('testvar').with_message('parent')
    end
  end

  context 'when loading data from a hash-typed lookup' do
    let(:facts) { { 'hiera_path' => 'hash-type' } }

    it { is_expected.to compile }
  end

  context 'when all changes are permitted' do
    permitted_risk = {
      'test'             => true,
      'block'            => true,
      'inner'            => true,
      'block_inner_diff' => true,
    }

    let(:facts) { { 'arbiter' => { 'permitted_risk' => permitted_risk } } }

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

    let(:facts) { { 'arbiter' => { 'permitted_risk' => permitted_risk } } }

    it { is_expected.to compile }

    include_examples 'correct resource tagging'
    include_examples 'correct noop setting', permitted_risk: permitted_risk
  end
end
