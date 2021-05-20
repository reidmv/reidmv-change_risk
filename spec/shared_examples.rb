RSpec.shared_examples 'a change_risk tagged resource' do |title:, risk:, type: 'notify'|
  res = "#{type.capitalize}[#{title}]"
  it "#{res} is tagged change_risk:#{risk}" do
    expect(catalogue.resource(res).tagged?("change_risk:#{risk}")).to be(true)
  end
end

RSpec.shared_examples 'a resource with noop value' do |title:, noop:, type: 'notify'|
  if noop.nil?
    it { is_expected.to send("contain_#{type}", title).without_noop }
  else
    it { is_expected.to send("contain_#{type}", title).with_noop(noop) }
  end
end

RSpec.shared_examples 'correct resource tagging' do
  it 'does not tag any resources with more than one change_risk tag' do
    expect(catalogue.resources.any? { |r| (r.tags.count { |t| t =~ %r{^change_risk:} }) > 1 }).to be(false)
  end

  describe 'resources in the test class' do
    include_examples 'a change_risk tagged resource', title: 'test-1', risk: 'test'
    include_examples 'a change_risk tagged resource', title: 'test-2', risk: 'test'
  end

  describe 'resources inside the test class\'s` change_risk() || {}` block' do
    include_examples 'a change_risk tagged resource', title: 'block-1', risk: 'block'
    include_examples 'a change_risk tagged resource', title: 'block-2', risk: 'block'
  end

  describe 'resources in the test::inner class' do
    include_examples 'a change_risk tagged resource', title: 'inner-1', risk: 'inner'
    include_examples 'a change_risk tagged resource', title: 'inner-2', risk: 'inner'
  end

  describe 'resources in the test::block_inner_same class' do
    include_examples 'a change_risk tagged resource', title: 'block-inner-same', risk: 'block'
  end

  describe 'resources in the test::block_inner_diff class' do
    include_examples 'a change_risk tagged resource', title: 'block-inner-diff', risk: 'block_inner_diff'
  end

  describe 'resources from the defined type in the test class\'s` change_risk() || {}` block' do
    include_examples 'a change_risk tagged resource', title: 'block-type-1', risk: 'block'
  end
end

RSpec.shared_examples 'correct noop setting' do |permitted_risk:|
  # Invert the permitted_risk hash to get the expected noop value.
  # permitted == true,  noop == nil
  # permitted == true,  noop == nil
  # permitted == nil,   NOT TESTED FOR
  noop_for = permitted_risk.each_with_object({}) { |(k, v), memo| memo[k] = true if v == false; }

  describe 'the test class' do
    include_examples 'a resource with noop value', title: 'test-1', noop: noop_for['test']
    include_examples 'a resource with noop value', title: 'test-2', noop: noop_for['test']
  end

  describe 'the test class\'s` change_risk() || {}` block' do
    include_examples 'a resource with noop value', title: 'block-1', noop: noop_for['block']
    include_examples 'a resource with noop value', title: 'block-2', noop: noop_for['block']
  end

  describe 'the test::inner class' do
    include_examples 'a resource with noop value', title: 'inner-1', noop: noop_for['inner']
    include_examples 'a resource with noop value', title: 'inner-2', noop: noop_for['inner']
  end

  describe 'Test::Type[type-1]' do
    include_examples 'a resource with noop value', title: 'type-1', noop: noop_for['test']
  end

  describe 'Test::Type[block-type-1]' do
    include_examples 'a resource with noop value', title: 'block-type-1', noop: noop_for['block']
  end
end
