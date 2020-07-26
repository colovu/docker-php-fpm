FROM endial/debian:10

ENV APP_MAJOR       5.0
#ENV APP_VERSION		10.12-2.pgdg18.04+1

LABEL \
	"Version"="v5.0" \
	"Description"="Docker image for php 5.0 with php-fpm based on Ubuntu 18.04." \
	"Dockerfile"="https://github.com/endial/docker-php" \
	"Vendor"="Endial Fang (endial@126.com)"

RUN set -eux; \
	groupadd -r php; \
	useradd -r -g php -s /usr/sbin/nologin -d /usr/cache/php5 php; \
	\
	mkdir -p /etc/php5 /srv/conf/php5 /var/log/php5 /var/run/php5 /var/cache/php5; \
	\
# 设置程序使用静默安装，而非交互模式；类似tzdata等程序需要使用静默安装
	export DEBIAN_FRONTEND=noninteractive; \
	\
# 更新源，并安装临时使用的软件包（使用完后可删除）
	fetchDeps=" \
# 下载工具
		ca-certificates \
		wget \
	"; \
	apt update; \
	apt install -y --no-install-recommends ${fetchDeps}; \
	\
# 安装应用程序及需要依赖的软件包
	apt install -y \
		curl openssl \
		php5 php5-fpm php5-mcrypt php5-curl php5-gd php5-json php5-openssl php5-opcache php5-zip \
		php5-mysql php5-mysqli php5-pdo_mysql php5-pdo_sqlite php5-phar php5-iconv php5-soap \
		php5-ldap php5-gettext php5-xml php5-xsl php5-dom php5-exif php5-sockets \
	; \
	\
# 设置临时目录的权限信息，设置为777是为了保证后续使用`--user`或`gosu`时，可以更改目录对应的用户属性信息
	chown -Rf php:php /etc/php5 /srv/conf/php5 /var/log/php5 /var/run/php5 /var/cache/php5; \
# this 777 will be replaced by 700 or 755 at runtime (allows semi-arbitrary "--user" values)
	chmod 777 /etc/php5 /srv/conf/php5 /var/log/php5 /var/run/php5 /var/cache/php5; \
	\
# 删除临时软件包，清理缓存
	apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*;


COPY ./entrypoint.sh /usr/local/bin/
COPY ./php5 /etc/php5

VOLUME ["/srv/conf", "/srv/www", "/var/log", "/var/run"]

# 如果使用gosu启动，必须保证端口在1024之上
EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm5", "-R", "-F", "-c", "/srv/conf/php5/php.ini", "-y", "/srv/conf/php5/php-fpm.conf"]
