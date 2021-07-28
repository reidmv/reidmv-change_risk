type Change_risk::Permitted = Variant[
  Hash[String, Change_risk::Boolean],
  Pattern[/^{((['"][\w-]*['"] *=> *(true|false)(, *)?)+)?}$/]
]
