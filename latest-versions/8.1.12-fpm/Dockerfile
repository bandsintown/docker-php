FROM bandsintown/alpine:3.15.0 as builder

FROM php:8.1.12-fpm-alpine

ENV S6_LOGGING=1 S6_OVERLAY_VERSION=1.19.1.1 GODNSMASQ_VERSION=1.0.7 CONSUL_TEMPLATE_VERSION=0.19.4 CONSUL_VERSION=0.8.4 MEMCACHED_DEPS="zlib-dev libmemcached-dev cyrus-sasl-dev" TZ="America/New_York"

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
      libpng-dev \
      curl wget bash tree jq bind-tools su-exec build-base gcc autoconf \
      libmemcached-libs zlib \
    && set -xe \
    && apk add --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --virtual .memcached-deps $MEMCACHED_DEPS \
    && pecl install memcached-3.1.4 \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20_memcached.ini \
    && pecl install memcache \
    && echo "extension=memcache.so" > /usr/local/etc/php/conf.d/21_memcache.ini \
    && docker-php-ext-install mysqli \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && rm -rf /usr/share/php8 \
    && rm -rf /tmp/* \
    && apk del .memcached-deps .phpize-deps

RUN curl -Ls https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar -xz -C /

RUN mkdir /var/composer && \
    cd /var/composer && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

COPY rootfs /

RUN echo $TZ > /etc/timezone \
    && touch /usr/local/var/run/php-fpm.pid \
    && echo -ne "- with $(php -v | head -n 1)\n" >> /root/.built

EXPOSE 9000

# Workaround https://bugs.php.net/bug.php?id=71880
ENV LOG_STREAM="/tmp/stdout"
RUN mkfifo $LOG_STREAM && chmod 777 $LOG_STREAM

ENTRYPOINT ["/init"]
CMD ["/bin/sh", "-c", "php-fpm --pid /usr/local/var/run/php-fpm.pid | tail -f $LOG_STREAM"]
