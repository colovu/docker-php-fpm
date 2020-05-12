FROM colovu/ubuntu:18.04

ENV APP_MAJOR=7.2 \
	APP_VERSION=7.2.24-0ubuntu0.18.04.4

LABEL \
	"Version"="v7.2" \
	"Description"="Docker image for php 7.2 with php-fpm based on Ubuntu 18.04." \
	"Dockerfile"="https://github.com/colovu/docker-php" \
	"Vendor"="Endial Fang (endial@126.com)"

RUN set -eux; \
# 设置程序使用静默安装，而非交互模式；类似tzdata等程序需要使用静默安装
	export DEBIAN_FRONTEND=noninteractive; \
	\
	groupadd -r php; \
	useradd -r -g php -s /usr/sbin/nologin -d /usr/cache/php7 php; \
	\
	mkdir -p /etc/php7 /srv/conf/php7 /var/log/php7 /var/run/php7 /var/cache/php7; \
	\
# 更新源，并安装临时使用的软件包（使用完后可删除）
	fetchDeps=" \
		ca-certificates \
		wget \
	"; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt update; \
	apt install -y --no-install-recommends ${fetchDeps}; \
	\
# 安装应用程序及需要依赖的软件包
	apt install -y \
		curl openssl \
		php7.2 \
		php7.2-bcmath php7.2-bz2 php7.2-curl \
		php7.2-dba php7.2-fpm php7.2-gd php7.2-gmp \
		php7.2-interbase php7.2-intl php7.2-json php7.2-ldap \
		php7.2-mbstring php7.2-mysql php7.2-odbc php7.2-opcache \
		php7.2-pgsql php7.2-pspell php7.2-readline php7.2-recode \
		php7.2-soap php7.2-sqlite3 php7.2-sybase \
		php7.2-tidy php7.2-xml php7.2-xmlrpc php7.2-xsl php7.2-zip \
# php7.2-cgi php7.2-cli php7.2-imap php7.2-snmp
	; \
	\
# 为中国区使用重新配置tzdata信息
	ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
	dpkg-reconfigure -f noninteractive tzdata; \
	\
	sed -ri 's/^(listen) .*$/\1 = 9000/' /etc/php/7.2/fpm/pool.d/www.conf; \
	\
# 设置临时目录的权限信息，设置为777是为了保证后续使用`--user`或`gosu`时，可以更改目录对应的用户属性信息
	chown -Rf php:php /etc/php7 /srv/conf/php7 /var/log/php7 /var/run/php7 /var/cache/php7; \
	chmod 777 /etc/php7 /srv/conf/php7 /var/log/php7 /var/run/php7 /var/cache/php7; \
	\
# 查找新安装的应用相应的依赖软件包，并表示为'manual'，防止后续自动清理时被删除
	apt-mark auto '.*' > /dev/null; \
	{ [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual; \
	\
# 删除临时软件包，清理缓存
	apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*;


COPY ./entrypoint.sh /usr/local/bin/
COPY ./php7/* /etc/php/7.2/fpm/

VOLUME ["/srv/conf", "/srv/www", "/var/log", "/var/run"]

# 如果使用gosu启动，必须保证端口在1024之上
EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm7.2", "-F", "-c", "/srv/conf/php7/php.ini", "-y", "/srv/conf/php7/php-fpm.conf"]
