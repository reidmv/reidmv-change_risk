node 'scoping' {
  include test
}

node 'risk-not-found' {
  change_risk('not-found')
  notify { 'test': }
}

node 'disable-mechanism' {
  change_risk('test')
  notify { 'test': }
}
