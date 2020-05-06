# frozen_string_literal: true

require 'spec_helper'

describe 'change_risk::test::init' do
  context 'basic usage' do
    it { is_expected.to compile }

    it 'should not tag resources with more than one change_risk tag' do
      expect(catalogue.resources.any? { |r| r.tags.select { |t| t =~ /change_risk:/ }.count > 1 }).to be(false)
    end

    it 'should tag init resources change_risk:low' do
      ['Notify[init-1]', 'Notify[init-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:low')).to be(true)
      end
    end

    it 'should tag resources inside the block change_risk:high' do
      ['Notify[block-1]', 'Notify[block-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:high')).to be(true)
      end
    end

    it 'should tag resources in the inner class change_risk:inner' do
      ['Notify[inner-1]', 'Notify[inner-2]'].each do |res|
        expect(catalogue.resource(res).tagged?('change_risk:inner')).to be(true)
      end
    end
  end
end
