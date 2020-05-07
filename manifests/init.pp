class change_risk (
  # $permitted_risk should be set to a hash such as the following:
  #
  # { 'high'    => false,
  #   'medium'  => true,
  #   'low'     => true,
  #   'unknown' => true }
  #
  Hash[String, Variant[Enum['true','false'], Boolean]] $permitted_risk = {},
  Enum[fail,none,noop]  $risk_not_found_action        = 'fail',
  Boolean               $ignore_permitted_risk        = false,
  Boolean               $respect_noop_class_interface = true,
  Enum[flag,fact,both]  $disable_mechanism            = 'flag',
) {
  # This class is a namespace for change_risk configuration information.
  # That is all.
}
