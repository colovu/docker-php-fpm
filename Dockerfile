# Ver: 1.8 by Endial Fang (endial@126.com)
#

# 可变参数 ========================================================================

# 设置当前应用名称及版本
ARG app_name=php
ARG app_version=8.0.8

# 设置默认仓库地址，默认为 阿里云 仓库
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"

# 设置 apt-get 源：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""


# 0. 预处理 ======================================================================
FROM ${registry_url}/colovu/dbuilder as builder

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source};

# 安装依赖的软件包及库(Optional)
RUN install_pkg libxml2-dev libsqlite3-dev zlib1g-dev systemtap-sdt-dev \
	libzip-dev libbz2-dev libonig-dev  libcurl4-gnutls-dev libxslt1-dev \
	libreadline-dev libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev libgmp-dev

# 设置工作目录
WORKDIR /tmp

# 下载并解压软件包
RUN set -eux; \
	appName=${app_name}-${app_version}.tar.gz; \
	sha256="84b09e4617e960b36dfa15fdbf2e3cd7141a2e877216ea29391b12ae86963cf4"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/${app_name}; \
	appUrls="${localURL:-} \
		https://www.php.net/distributions \
		"; \
	download_pkg unpack ${appName} "${appUrls}";

# 源码编译
RUN set -eux; \
	APP_SRC="/tmp/${app_name}-${app_version}"; \
	cd ${APP_SRC}; \
	./configure \
		--prefix=/usr/local/${app_name} \
		--disable-debug \
		--disable-rpath \
		--enable-fpm \
		--enable-inline-optimization \
		--enable-shared \
		--enable-opcache \
		--enable-mbstring \
		--enable-soap \
		--enable-dtrace \
		--enable-bcmath \
		--enable-pcntl \
		--enable-shmop \
		--enable-sockets \
		--enable-sysvmsg \
		--enable-sysvsem \
		--enable-sysvshm \
		--enable-maintainer-zts \
		--enable-calendar \
		--enable-exif \
		--enable-ftp \
		--enable-gd \
		--enable-gd-jis-conv \
		--with-xmlrpc \
		--with-gmp \
		--with-jpeg \
		--with-freetype \
		--with-webp \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-gettext \
		--with-mhash \
		--with-openssl \
		--with-curl \
		--with-zlib \
		--with-zip \
		--with-bz2 \
		--with-readline \
		--with-xsl \
		--with-pear \
		; \
	make -j "$(nproc)"; \
	make install; \
	cp ${APP_SRC}/php.ini-* /usr/local/${app_name}/etc/; \
	cp ${APP_SRC}/php.ini-production /usr/local/${app_name}/etc/php.ini; \
	cp /usr/local/${app_name}/etc/php-fpm.conf.default /usr/local/${app_name}/etc/php-fpm.conf; \
	cp /usr/local/${app_name}/etc/php-fpm.d/www.conf.default /usr/local/${app_name}/etc/php-fpm.d/www.conf; \
	strip /usr/local/php/bin/php /usr/local/php/bin/php-cgi /usr/local/php/bin/phpdbg /usr/local/php/sbin/php-fpm;

# --with-fpm-user=www --with-fpm-group=www              

# 删除编译生成的多余文件
RUN set -eux; \
	find /usr/local -name '*.a' -delete; \
	rm -rf /usr/local/${app_name}/php; \
	rm -rf /usr/local/${app_name}/include;

# 检测并生成依赖文件记录
RUN set -eux; \
	find /usr/local/${app_name} -type f -executable -exec ldd '{}' ';' | \
		awk '/=>/ { print $(NF-1) }' | \
		sort -u | \
		xargs -r dpkg-query --search 2>/dev/null | \
		cut -d: -f1 | \
		sort -u >/usr/local/${app_name}/runDeps;


# 1. 生成镜像 =====================================================================
FROM ${registry_url}/colovu/debian:buster

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url

# 镜像所包含应用的基础信息，定义环境变量，供后续脚本使用
ENV APP_NAME=${app_name} \
	APP_EXEC=php-fpm \
	APP_VERSION=${app_version}

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME}

ENV PATH="${APP_HOME_DIR}/sbin:${APP_HOME_DIR}/bin:${PATH}" \
	LD_LIBRARY_PATH="${APP_HOME_DIR}/lib"

LABEL \
	"Version"="v${app_version}" \
	"Description"="Docker image for ${app_name}(v${app_version})." \
	"Dockerfile"="https://github.com/colovu/docker-${app_name}" \
	"Vendor"="Endial Fang (endial@126.com)"

# 从预处理过程中拷贝软件包(Optional)，可以使用阶段编号或阶段命名定义来源
COPY --from=0 /usr/local/${APP_NAME} /usr/local/${APP_NAME}

# 拷贝应用使用的客制化脚本，并创建对应的用户及数据存储目录
COPY customer /
RUN set -eux; \
	prepare_env; \
	/bin/bash -c "ln -sf /usr/local/${APP_NAME}/etc /etc/${APP_NAME}";

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source}

# 安装依赖的软件包及库(Optional)
RUN install_pkg `cat /usr/local/${APP_NAME}/runDeps`; 
#RUN install_pkg bash sudo libssl1.1

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	${APP_EXEC} -v ;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/srv/cert", "/var/log"]

# 默认non-root用户启动，必须保证端口在1024之上
EXPOSE 9000

# 关闭基础镜像的健康检查
#HEALTHCHECK NONE

# 应用健康状态检查
#HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
#	CMD curl -fs http://localhost:8080/ || exit 1
HEALTHCHECK --interval=10s --timeout=10s --retries=3 \
	CMD netstat -ltun | grep 9000

# 使用 non-root 用户运行后续的命令
USER 1001

# 设置工作目录
WORKDIR /srv/data

# 容器初始化命令
ENTRYPOINT ["/usr/local/bin/entry.sh"]

# 应用程序的启动命令，必须使用非守护进程方式运行
CMD ["/usr/local/bin/run.sh"]

