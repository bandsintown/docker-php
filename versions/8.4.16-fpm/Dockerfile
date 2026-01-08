FROM surnet/alpine-wkhtmltopdf:3.19.0-0.12.6-full as wkhtmltopdf

FROM php:8.4.16-fpm-alpine

ENV S6_LOGGING=1 S6_OVERLAY_VERSION=1.19.1.1 GODNSMASQ_VERSION=1.0.7 CONSUL_TEMPLATE_VERSION=0.32.0 CONSUL_VERSION=1.15.0 MEMCACHED_DEPS="zlib-dev libmemcached-dev cyrus-sasl-dev" TZ="America/New_York"

# Download architecture-specific binaries (newer versions with ARM64 support)
RUN apk add --no-cache unzip && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then CONSUL_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then CONSUL_ARCH="arm64"; \
    else CONSUL_ARCH="amd64"; fi && \
    # Download consul
    wget -O /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${CONSUL_ARCH}.zip && \
    unzip /tmp/consul.zip -d /usr/local/bin && \
    rm /tmp/consul.zip && \
    # Download consul-template
    wget -O /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_${CONSUL_ARCH}.zip && \
    unzip /tmp/consul-template.zip -d /usr/local/bin && \
    rm /tmp/consul-template.zip && \
    chmod +x /usr/local/bin/consul /usr/local/bin/consul-template && \
    apk del unzip

# Copy s6 overlay configs (these are just scripts, not binaries)
RUN mkdir -p /etc/cont-init.d /etc/services.d /root

RUN apk update && apk upgrade \
    && apk add --no-cache \
      coreutils \
      freetype-dev \
      libjpeg-turbo-dev \
      libtool \
      libpng-dev \
      curl wget bash tree jq bind-tools build-base gcc autoconf \
      zlib \
      libmemcached-dev \
      cyrus-sasl-dev \
      zlib-dev \
      linux-headers \
      $PHPIZE_DEPS \
    && pecl install memcached-3.3.0 \
    && docker-php-ext-enable memcached \
    && pecl install memcache \
    && docker-php-ext-enable memcache \
    && docker-php-ext-install mysqli \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install bcmath \
    && rm -rf /tmp/pear

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then S6_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then S6_ARCH="aarch64"; \
    else S6_ARCH="amd64"; fi && \
    curl -Ls https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz | tar -xz -C /

# Install Composer - disable xdebug during build
RUN XDEBUG_MODE=off curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN echo $TZ > /etc/timezone \
    && touch /usr/local/var/run/php-fpm.pid \
    && echo -ne "- with $(php -v | head -n 1)\n" >> /root/.built

EXPOSE 9000

# Workaround https://bugs.php.net/bug.php?id=71880
ENV LOG_STREAM="/tmp/stdout"
RUN mkfifo $LOG_STREAM && chmod 777 $LOG_STREAM

ENTRYPOINT ["/init"]
CMD ["/bin/sh", "-c", "/usr/local/sbin/php-fpm --pid /usr/local/var/run/php-fpm.pid | tail -f $LOG_STREAM"]