RSpec.configure do |c|
  c.hiera_config = File.join(File.dirname(__FILE__), 'fixtures', 'hiera.yaml')
end
