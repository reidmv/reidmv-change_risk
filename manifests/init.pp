class change_risk (
  # $permitted_risk should be set to a hash such as the following:
  #
  # { 'high'    => false,
  #   'medium'  => true,
  #   'low'     => true,
  #   'unknown' => true }
  #
  Change_risk::Permitted $permitted_risk               = {},
  Enum[fail,none,noop]   $risk_not_found_action        = 'fail',
  Change_risk::Boolean   $ignore_permitted_risk        = false,
  Enum[flag,fact,both]   $disable_mechanism            = 'flag',
  Change_risk::Boolean   $respect_noop_class_interface = true,
) {
  # This class is a namespace for change_risk configuration information.
  # That is all.
}
