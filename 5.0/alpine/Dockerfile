FROM endial/alpine:v3.6

LABEL \
	"Version"="v5.0" \
	"Description"="Docker for PHP-FPM 5.0 based on Alpine 3.11." \
	"Dockerfile"="https://github.com/endial/docker-libs" \
	"Vendor"="Endial Fang (endial@126.com)"

RUN  apk update \
  && apk add curl openssl \
  && apk add php5 php5-fpm php5-mcrypt php5-curl php5-gd php5-json php5-openssl php5-opcache php5-zip \
  && apk add php5-mysql php5-mysqli php5-pdo_mysql php5-pdo_sqlite php5-phar php5-iconv php5-soap \
  && apk add php5-ldap php5-gettext php5-xml php5-xsl php5-dom php5-exif php5-sockets \
  && mkdir -p /etc/php5 \
  && apk add tzdata \
  && cp /usr/share/zoneinfo/PRC /etc/localtime \
  && echo "PRC" > /etc/timezone \
  && apk del tzdata \
  && rm -rf /var/cache/apk/*

COPY ./php5 /etc/php5

EXPOSE 9000

VOLUME ["/srv/conf", "/srv/www", "/var/log", "/var/run"]

ENTRYPOINT ["/etc/php5/entrypoint.sh"]

CMD ["php-fpm5", "-R", "-F", "-c", "/srv/conf/php5/php.ini", "-y", "/srv/conf/php5/php-fpm.conf"]
