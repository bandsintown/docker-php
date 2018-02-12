@test "'php-fpm' should be present" {
  run which php-fpm
  [ $status -eq 0 ]
}

@test "'/usr/local/etc/php/php.ini' file should be present" {
  run ls /usr/local/etc/php/php.ini
  [ $status -eq 0 ]
}

@test "'/usr/local/etc/php-fpm.d/docker.conf' file should be present" {
  run ls /usr/local/etc/php-fpm.d/docker.conf
  [ $status -eq 0 ]
}

@test "a '/tmp/stdout' pipe should be present" {
  run test -p /tmp/stdout
  [ $status -eq 0 ]
}

@test "the environment variable LOG_STREAM is set" {
  run test -n "${LOG_STREAM}"
  [ $status -eq 0 ]
}
