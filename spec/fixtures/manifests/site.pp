node 'scoping' {
  include test
}

node 'risk-not-found' {
  change_risk('not-found')
  notify { 'test': }
}
