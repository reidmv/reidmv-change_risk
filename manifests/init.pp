# Pocketwach provides business and operational data about a node sourced from
# ServiceNow, the system of record for this information. The pocketwatch class
# provides a way to query and save the result during a Puppet run without a
# topscope variable in site.pp. The $pocketwatch::data variable, once
# pocketwatch has been included, makes this information available for Puppet to
# use in configuration management decision making.
class pocketwatch {
  $data = pocketwatch::lookup(getvar('trusted.certname'))

  # Expect a hash of data back. The hash should include a key "permitted", which
  # has the following structure (sample data):
  #
  #  {
  #    'permitted' => {
  #      'high'    => false,
  #      'medium'  => false,
  #      'low'     => true,
  #      'unknown' => false,
  #   }
  # }
}
