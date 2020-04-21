#!/bin/bash
# 
# docker entrypoint script

set -Eeo pipefail

LOG_RAW() {
	local type="$1"; shift
	printf '%s [%s] Entrypoint: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$type" "$*"
}
LOG_I() {
	LOG_RAW Note "$@"
}
LOG_W() {
	LOG_RAW Warn "$@" >&2
}
LOG_E() {
	LOG_RAW Error "$@" >&2
	exit 1
}

LOG_I "Initial container for php7"

# 检测当前脚本是被直接执行的，还是从其他脚本中使用 "source" 调用的
_is_sourced() {
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

# 使用root用户运行时，创建默认的数据目录，并拷贝所必须的默认配置文件及初始化文件
# 修改对应目录所属用户为应用对应的用户(Docker镜像创建时，相应目录默认为777模式)
docker_create_user_directories() {
	local user_id; user_id="$(id -u)"

	LOG_I "Check directories used by php7"
	mkdir -p "/var/log/php7"
	mkdir -p "/var/run/php7"
	mkdir -p "/var/cache/php7"

	mkdir -p "/srv/conf/php7"
	# 检测指定文件是否存在，如果不存在则拷贝
	[ ! -e /srv/conf/php7/php.ini ] && cp /etc/php/7.2/fpm/php.ini /srv/conf/php7/php.ini
	[ ! -e /srv/conf/php7/php-fpm.conf ] && cp /etc/php/7.2/fpm/php-fpm.conf /srv/conf/php7/php-fpm.conf
	
	mkdir -p /srv/conf/php7/conf.d
	mkdir -p /srv/conf/php7/pool.d/
	[ ! -e /srv/conf/php7/pool.d/www.conf ] && cp /etc/php/7.2/fpm/pool.d/www.conf /srv/conf/php7/pool.d/www.conf

	# 允许容器使用`--user`参数启动，修改相应目录的所属用户信息
	# 如果设置了'--user'，这里 user_id 不为 0
	# 如果没有设置'--user'，这里 user_id 为 0，需要使用默认用户名设置相关目录权限
	if [ "$user_id" = '0' ]; then
		find /var/run/php7 \! -user php -exec chown php '{}' +
		find /var/log/php7 \! -user php -exec chown php '{}' +
		find /var/cache/php7 \! -user php -exec chown php '{}' +
		find /srv/conf/php7 \! -user php -exec chown php '{}' +
				# 修改目录读写属性，使用`:`命令是为了保证不会因部分目录权限问题，导致命令失败而使得容器退出
		chmod 755 /etc/nginx /var/log/nginx /var/cache/nginx /var/run/nginx /srv/conf/nginx || :
		# 解决使用gosu后，nginx: [emerg] open() "/dev/stdout" failed (13: Permission denied)
		chmod 0622 /dev/stdout /dev/stderr
	fi
}

# 检测可能导致容器执行后直接退出的命令，如"--help"；如果存在，直接返回 0
docker_app_want_help() {
	local arg
	for arg; do
		case "$arg" in
			-'?'|--help|-V|--version)
				return 0
				;;
		esac
	done
	return 1
}

_main() {
	# 如果命令行参数是以配置参数("-")开始，修改执行命令，确保使用可执行应用命令启动服务器
	if [ "${1:0:1}" = '-' ]; then
		set -- php-fpm7.2 "$@"
	fi

	# 命令行参数以可执行应用命令起始，且不包含直接返回的命令(如：-V、--version、--help)时，执行初始化操作
	if [ "$1" = "php-fpm7.2" ] && ! docker_app_want_help "$@"; then
		# docker_setup_env

		# 创建并设置数据存储目录与权限
		docker_create_user_directories

		# 以root用户运行时，使用gosu重新以"postgres"用户运行当前脚本
		if [ "$(id -u)" = '0' ]; then
			LOG_I "Restart container with default user: php'"
			LOG_I ""
			exec gosu php "$0" "$@"
		fi
	fi

	LOG_I "Start container with: $@"
	# 执行命令行
	exec "$@"
}

if ! _is_sourced; then
	_main "$@"
fi
