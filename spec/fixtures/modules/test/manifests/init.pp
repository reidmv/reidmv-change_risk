class test {
  change_risk('test')

  notify { 'test-1': }

  change_risk('block') || {
    notify { 'block-1': }
    notify { 'block-2': }

    include test::block_inner_same
    include test::block_inner_diff
  }

  notify { 'test-2': }

  include test::inner
}
