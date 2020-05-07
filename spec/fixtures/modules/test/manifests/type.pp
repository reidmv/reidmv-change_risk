define test::type (
  String $message,
) {

  notify { $title:
    message => $message,
  }

}
