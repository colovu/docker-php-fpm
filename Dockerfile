# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 指定原始系统镜像，常用镜像为 colovu/ubuntu:18.04、colovu/debian:10、colovu/alpine:3.12、colovu/openjdk:8u252-jre
FROM colovu/debian:10

# ARG参数使用"--build-arg"指定，如 "--build-arg apt_source=tencent"
# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=default

# 外部指定应用版本信息，如 "--build-arg app_ver=6.0.0"
ARG app_ver=7.4

# 编译镜像时指定本地服务器地址，如 "--build-arg local_url=http://172.29.14.108/dist-files/"
ARG local_url=""

# 定义应用基础常量信息，该常量在容器内可使用
ENV APP_NAME=php \
	APP_EXEC=php-fpm${app_ver} \
	APP_VERSION=${app_ver}

# 定义应用基础目录信息，该常量在容器内可使用
ENV	APP_DEF_DIR=/etc/${APP_NAME} \
	APP_CONF_DIR=/srv/conf/${APP_NAME}/${APP_VERSION} \
	APP_DATA_DIR=/srv/data/${APP_NAME} \
	APP_DATA_LOG_DIR=/srv/datalog/${APP_NAME} \
	APP_CACHE_DIR=/var/cache/${APP_NAME} \
	APP_RUN_DIR=/var/run/${APP_NAME} \
	APP_LOG_DIR=/var/log/${APP_NAME} \
	APP_CERT_DIR=/srv/cert/${APP_NAME}

LABEL \
	"Version"="v${app_ver}" \
	"Description"="Docker image for ${APP_NAME}(v${app_ver})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

# 拷贝默认 Shell 脚本至容器相关目录中
COPY prebuilds /

# 镜像内相应应用及依赖软件包的安装脚本；以下脚本可按照不同需求拆分为多个段，但需要注意各个段在结束前需要清空缓存
RUN \
# 设置程序使用静默安装，而非交互模式；默认情况下，类似 tzdata/gnupg/ca-certificates 等程序配置需要交互
	export DEBIAN_FRONTEND=noninteractive; \
	\
# 设置 shell 执行参数，分别为 -e(命令执行错误则退出脚本) -u(变量未定义则报错) -x(打印实际待执行的命令行)
	set -eux; \
	\
# 更改源为当次编译指定的源
	cp /etc/apt/sources.list.${apt_source} /etc/apt/sources.list; \
	\
# 为应用创建对应的组、用户、相关目录
	export APP_DIRS="${APP_DEF_DIR:-} ${APP_CONF_DIR:-} ${APP_DATA_DIR:-} ${APP_CACHE_DIR:-} ${APP_RUN_DIR:-} ${APP_LOG_DIR:-} ${APP_CERT_DIR:-} ${APP_DATA_LOG_DIR:-} ${APP_HOME_DIR:-${APP_DATA_DIR}}"; \
	mkdir -p ${APP_DIRS}; \
	groupadd -r -g 998 ${APP_NAME}; \
	useradd -r -g ${APP_NAME} -u 999 -s /usr/sbin/nologin -d ${APP_DATA_DIR} ${APP_NAME}; \
	\
# 应用软件包及依赖项。相关软件包在镜像创建完成时，不会被清理
	appDeps=" \
		curl \
		ca-certificates \
		\
		openssl \
		php${APP_VERSION} \
		php${APP_VERSION}-bcmath php${APP_VERSION}-bz2 php${APP_VERSION}-cgi php${APP_VERSION}-cli \
		php${APP_VERSION}-common php${APP_VERSION}-curl php${APP_VERSION}-dba php${APP_VERSION}-enchant \
		php${APP_VERSION}-fpm php${APP_VERSION}-gd php${APP_VERSION}-gmp php${APP_VERSION}-imap \
		php${APP_VERSION}-interbase php${APP_VERSION}-intl php${APP_VERSION}-json php${APP_VERSION}-ldap \
		php${APP_VERSION}-mbstring php${APP_VERSION}-mysql php${APP_VERSION}-odbc php${APP_VERSION}-opcache \
		php${APP_VERSION}-pgsql php${APP_VERSION}-phpdbg php${APP_VERSION}-pspell php${APP_VERSION}-readline \
		php${APP_VERSION}-snmp php${APP_VERSION}-soap php${APP_VERSION}-sqlite3 php${APP_VERSION}-sybase \
		php${APP_VERSION}-tidy php${APP_VERSION}-xml php${APP_VERSION}-xmlrpc php${APP_VERSION}-xsl php${APP_VERSION}-zip \
	"; \
	savedAptMark="$(apt-mark showmanual) ${appDeps}"; \
	\
	\
	\
# 安装临时使用的软件包及依赖项。相关软件包在镜像创建完后时，会被清理
	fetchDeps=" \
		wget \
		ca-certificates \
		\
		apt-transport-https \
		lsb-release \
		\
		gnupg \
		dirmngr \
	"; \
	apt update; \
	apt upgrade -y; \
	apt install -y --no-install-recommends ${fetchDeps}; \
	\

# 包管理方式安装: 增加软件包特有源，并使用系统包管理方式安装软件; 安装后需要确认 ${APP_DEF_DIR} 目录中存在原始配置文件
	wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -; \
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list; \
	apt update; \
	apt upgrade -y; \
	apt install -y ${appDeps}; \
	\
	\
	\
# 设置应用关联目录的权限信息
	chown -Rf ${APP_NAME}:${APP_NAME} ${APP_DIRS}; \
	\
# 查找新安装的应用及应用依赖软件包，并标识为'manual'，防止后续自动清理时被删除
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
# 删除安装的临时依赖软件包，清理缓存
	apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt autoclean -y; \
	rm -rf /var/lib/apt/lists/*; \
	:;

# 拷贝应用专用 Shell 脚本至容器相关目录中
COPY customer /

RUN set -eux; \
# 设置容器入口脚本的可执行权限
	chmod +x /usr/local/bin/entrypoint.sh; \
	\
# 检测是否存在对应版本的 overrides 脚本文件；如果存在，执行
	{ [ ! -e "/usr/local/overrides/overrides-${app_ver}.sh" ] || /bin/bash "/usr/local/overrides/overrides-${app_ver}.sh"; }; \
	\
# 验证安装的软件是否可以正常运行，常规情况下放置在命令行的最后
	gosu ${APP_NAME} ${APP_EXEC} --version ; \
	:;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/srv/cert", "/var/log"]

# 默认使用gosu切换为新建用户启动，必须保证端口在1024之上
EXPOSE 9000

# 容器初始化命令，默认存放在：/usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

WORKDIR ${APP_DATA_DIR}

CMD ["${APP_EXEC}", "-R", "-F", "-c", "${APP_CONF_DIR}/fpm/php.ini", "-y", "${APP_CONF_DIR}/fpm/php-fpm.conf"]
