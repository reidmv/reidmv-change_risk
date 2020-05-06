class change_risk::test::init {
  class { 'change_risk':
    risk_permitted => {
      'low'   => true,
      'high'  => false,
      'inner' => false,
    },
  }

  change_risk('low')

  notify { 'init-1': }

  change_risk('high') || {
    notify { 'block-1': }
    notify { 'block-2': }
  }

  notify { 'init-2': }

  include change_risk::test::inner
}
