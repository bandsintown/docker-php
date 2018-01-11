FROM bandsintown/alpine:3.6 as builder

FROM php:5.6.32-fpm-alpine

ENV S6_OVERLAY_VERSION=1.19.1.1 GODNSMASQ_VERSION=1.0.7 CONSUL_TEMPLATE_VERSION=0.19.4 CONSUL_VERSION=0.8.4 MEMCACHED_DEPS="zlib-dev libmemcached-dev cyrus-sasl-dev" TZ="America/New_York"

COPY --from=builder /usr/local/bin/consul /usr/local/bin/consul
COPY --from=builder /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=builder /usr/sbin/go-dnsmasq /usr/sbin/go-dnsmasq
COPY --from=builder /etc/cont-init.d /etc/cont-init.d
COPY --from=builder /etc/services.d /etc/services.d
COPY --from=builder /root /root

RUN apk update && apk upgrade \
    && apk add --update \
      coreutils \
      freetype-dev \
      libjpeg-turbo-dev \
      libltdl \
      libmcrypt-dev \
      libpng-dev \
      curl wget bash tree jq bind-tools su-exec \
      libmemcached-libs zlib \
    && set -xe \
    && apk add --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached-2.2.0 \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20_memcached.ini \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && rm -rf /usr/share/php5 \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps

RUN curl -Ls https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar -xz -C /

RUN mkdir /var/composer \
    && cd /var/composer \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA1', 'composer-setup.php') === '43ac9d1da84cb7147ad7cf2b1796de8c2be51d5a') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');"

COPY rootfs /

RUN echo $TZ > /etc/timezone \
    && touch /usr/local/var/run/php-fpm.pid

EXPOSE 9000

ENV S6_LOGGING=1

ENTRYPOINT ["/init"]
CMD ["php-fpm", "--pid", "/usr/local/var/run/php-fpm.pid"]
