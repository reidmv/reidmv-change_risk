# frozen_string_literal: true

require 'spec_helper'

describe 'testnode' do
  context 'compiling a catalog that uses change_risk()' do
    let(:pre_condition) {
      <<-MANIFEST
        class { 'change_risk':
          risk_permitted => {
            'test'             => true,
            'block'            => true,
            'inner'            => true,
            'block_inner_same' => true,
            'block_inner_diff' => true,
          },
        }
      MANIFEST
    }

    it { is_expected.to compile }

    it 'should not tag any resources with more than one change_risk tag' do
      expect(catalogue.resources.any? { |r| r.tags.select { |t| t =~ /change_risk:/ }.count > 1 }).to be(false)
    end

    it 'should tag init.pp resources change_risk:test' do
      ['Notify[test-1]', 'Notify[test-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:test')).to be(true)
      end
    end

    it 'should tag resources inside the block change_risk:block' do
      ['Notify[block-1]', 'Notify[block-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:block')).to be(true)
      end
    end

    it 'should tag resources in the inner class change_risk:inner' do
      ['Notify[inner-1]', 'Notify[inner-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:inner')).to be(true)
      end
    end

    it 'should tag resources in the block-inner-same class change_risk:block' do
      ['Notify[block-inner-same]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:block')).to be(true)
      end
    end

    it 'should tag resources in the block-inner-diff class change_risk:block_inner_diff' do
      ['Notify[block-inner-diff]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:block_inner_diff')).to be(true)
      end
    end
  end
end
