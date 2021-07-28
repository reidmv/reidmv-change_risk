node 'class' {
  change_risk('not-permitted')
  notify { '1-should-be-noop': }
}

node 'block' {
  change_risk('not-permitted') || {
    notify { '1-should-be-noop': }
  }
}

node 'oscillating' {
  change_risk('permitted') || {
    notify { '1-should-be-op': }

    change_risk('not-permitted') || {
      notify { '2-should-be-noop': }

      change_risk('permitted') || {
        notify { '3-should-be-op': }

        change_risk('not-permitted') || {
          notify { '4-should-be-noop': }
        }
      }
    }
  }
}

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

node default { }
