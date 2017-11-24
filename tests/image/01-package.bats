@test "'php-fpm' should be present" {
  run which php-fpm
  [ $status -eq 0 ]
}
