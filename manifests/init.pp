class change_risk (
  # $risk_permitted should be set to a hash such as the following:
  #
  # { 'high'    => false,
  #   'medium'  => true,
  #   'low'     => true,
  #   'unknown' => true }
  #
  Hash[String, Boolean] $risk_permitted        = {},
  Enum[fail,op,noop]    $not_found_behavior    = 'fail',
  Boolean               $noop_unless_permitted = true,
  Boolean               $tag_change_risk       = true,
  Boolean               $implement_class_noop  = true,
  Enum[flag,fact,both]  $disable_mechanism     = 'flag',
) {
  # This class is a namespace for change_risk configuration information.
  # That is all.
}
