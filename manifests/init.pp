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
  # Because $permitted_risk may be passed in as a stringified hash, the
  # following variable is used to validate it and ensure access to a
  # properly typed Hash value.
  $permitted_risk_normalized = (type($permitted_risk) =~ Type[Hash]) ? {
    true  => $permitted_risk,
    false => $permitted_risk.regsubst(/(['"])(\w+)\1 *=>/, '"\2":', 'G').parsejson,
  }
}
