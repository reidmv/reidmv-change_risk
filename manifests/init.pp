# @summary configures the change_risk() function
#
# @see https://github.com/reidmv/reidmv-change_risk/blob/master/README.md
#
# @param permitted_risk
#   A hash of change risks and whether or not each is permissible
# @param risk_not_found_action
#   Which action to take when a risk 'x' is supplied, e.g. change_risk('x'),
#   but 'x' is not present in the permitted_risk hash.
# @param ignore_permitted_risk
#   When true, assumes risk is always permitted. Defaults to false.
# @param disable_mechanism
#   Which mechanism(s) can be used to ignore permitted risk on an ad-hoc basis.
# @param respect_noop_class_interface
#   When true, implements the semantics of noop::class_interface() in
#   conjuction with the normal behavior of change_risk(). Only affects the use
#   of change_risk() without a block.
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
