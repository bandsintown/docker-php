FROM bandsintown/php:5.6-fpm as builder

RUN echo http://dl-cdn.alpinelinux.org/alpine/v3.6/main >> /etc/apk/repositories \
    && echo http://dl-cdn.alpinelinux.org/alpine/v3.6/community >> /etc/apk/repositories

RUN apk update --no-cache && \
 	apk upgrade --no-cache  && \
 	apk add sudo abuild --virtual .build-deps

# compile cassandra
# the cassandra pecl v1.3.0+ needs cassandra-cpp-driver 1.7+
RUN apk add --no-cache cassandra-cpp-driver libuv gmp && \
	apk add --no-cache cassandra-cpp-driver-dev gmp-dev --virtual .build-sec && \
	pecl install cassandra-1.3.0 && \
	apk del .build-sec
	# disable by default
	#echo "extension=cassandra.so" > /etc/php5/conf.d/cassandra.ini

RUN adduser -D build && \
	addgroup build abuild && \
	sudo -H -u build mkdir /home/build/thrift && \
	sudo -H -u build mkdir /home/build/php5-pdo_cassandra && \
	sudo -H -u build abuild-keygen -an && \
	source /home/build/.abuild/abuild.conf && \
	cp "$PACKAGER_PRIVKEY".pub /etc/apk/keys/

# compile thrift
COPY APKBUILD-thrift /home/build/thrift/APKBUILD
RUN cd /home/build/thrift && \
	sudo -H -u build abuild -r && \
	apk add --no-cache /home/build/packages/build/x86_64/thrift*.apk && \
	echo "extension=thrift_protocol.so" > /usr/local/etc/php/conf.d/thrift_protocol.ini

# compile php5-pdo_cassandra
COPY APKBUILD-php5-pdo_cassandra /home/build/php5-pdo_cassandra/APKBUILD
RUN cd /home/build/php5-pdo_cassandra && \
	sudo -H -u build abuild -r && \
	apk add /home/build/packages/build/x86_64/php5-pdo_cassandra-0.6.0-r0.apk && \
	echo "extension=pdo_cassandra.so" > /usr/local/etc/php/conf.d/pdo_cassandra.ini

# cleaning
RUN deluser build && \
	rm -R /home/build && \
	apk del .build-deps

FROM bandsintown/php:5.6-fpm

COPY --from=builder /usr/local/etc/php/conf.d/*.ini /usr/local/etc/php/conf.d/
COPY --from=builder /usr/bin/thrift /usr/bin/thrift
COPY --from=builder /usr/include/thrift /usr/include/thrift
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /lib/libcrypto* /lib/
COPY --from=builder /usr/lib/libcrypto* /usr/lib/
COPY --from=builder /usr/lib/libcassandra* /usr/lib/
COPY --from=builder /usr/lib/libthrift* /usr/lib/
COPY --from=builder /usr/lib/libboost* /usr/lib/
