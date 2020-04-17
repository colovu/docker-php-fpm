#!/bin/sh
# docker entrypoint script

echo "[i] Initial Container"

if [ ! -d /srv/conf/php5 ]; then
  mkdir -p /srv/conf/php5
fi

if [ !  -f /srv/conf/php5/php.ini ]; then
  cp /etc/php5/php.ini /srv/conf/php5/
fi

if [ ! -f /srv/conf/php5/php-fpm.conf ]; then
  cp /etc/php5/php-fpm.conf /srv/conf/php5/
fi

if [ ! -d /var/log/php5 ]; then
  mkdir -p /var/log/php5
fi

if [ ! -d /var/run/php5 ]; then
  mkdir -p /var/run/php5
fi

# start service, move to CMD in Dockfile
#echo "[i] Start PHP-FPM with config /srv/conf/php5/php-fpm.conf"
#php-fpm5 -R -F -c /srv/conf/php5/php.ini -y /srv/conf/php5/php-fpm.conf

echo "[i] Start PHP-FPM with parameter: $@"
exec "$@"
