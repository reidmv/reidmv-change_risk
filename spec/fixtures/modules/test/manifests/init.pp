class test {
  change_risk('test')

  notify { 'test-1': }

  change_risk('block') || {
    notify { 'block-1': }
    notify { 'block-2': }

    test::type { 'block-type-1':
      message => 'block-type-1',
    }

    include test::block_inner_same
    include test::block_inner_diff
  }

  notify { 'test-2': }

  include test::inner

  test::type { 'type-1':
    message => 'type-1',
  }
}
