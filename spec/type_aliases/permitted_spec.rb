require 'spec_helper'

describe 'Change_risk::Permitted' do
  it { is_expected.to allow_value({"high" => false, "low" => true}) }
  it { is_expected.to allow_value({}) }
  it { is_expected.to allow_value('{"high" => false, "low" => true}') }
  it { is_expected.to allow_value('{}') }
  it { is_expected.not_to allow_value('{"boolean" => "false"}') }
end
