#!/usr/bin/env bash

echo "Reload script"
pid_php=$(cat /usr/local/var/run/php-fpm.pid)
if [ -n "$pid_php" ]; then
  echo "Reloading php configuration"
  kill -USR2 $pid_php
  echo "Configuration reloaded"
fi
