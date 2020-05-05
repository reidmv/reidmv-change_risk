Puppet::Functions.create_function(:'pocketwatch::lookup') do
  dispatch :lookup do
    param 'String', :certname
    return_type 'Hash'
  end

  def lookup(certname)
    # Mock values for now
    {
      'permitted' => {
        'unknown' => true,
        'low'     => true,
        'medium'  => true,
        'high'    => false,
      }
    }
  end
end

