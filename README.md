# PHP-FPM

针对 [PHP-FPM](https://www.php.net) 应用的 Docker 镜像，用于提供 PHP解析及PHP-FPM 服务。

使用说明可参照：[官方说明](https://www.php.net/docs.php)

<img src="img/php8-logo.svg" alt="php-fpm-logo" />

**版本信息：**

- 7.4、latest
- 7.3

**镜像信息：**

* 镜像地址：
  - 阿里云: registry.cn-shenzhen.aliyuncs.com/colovu/php-fpm:7.3
  - DockerHub：colovu/php-fpm:7.3
  * 依赖镜像：debian:buster

> 后续相关命令行默认使用`[Docker Hub](https://hub.docker.com)`镜像服务器做说明



## TL;DR

Docker 快速启动命令：

```shell
# 从 Docker Hub 服务器下载镜像并启动
$ docker run -d --name imgname colovu/php-fpm

# 从 Aliyun 服务器下载镜像并启动
$ docker run -d --name imgname registry.cn-shenzhen.aliyuncs.com/colovu/php-fpm
```

- `colovu/imgname:<TAG>`：镜像名称及版本标签；标签不指定时默认使用`latest`



Docker-Compose 快速启动命令：

```shell
# 从 Gitee 下载 Compose 文件
$ curl -sSL -o https://gitee.com/colovu/docker-php-fpm/raw/7.3/docker-compose.yml

# 从 Github 下载 Compose 文件
$ curl -sSL -o https://raw.githubusercontent.com/colovu/docker-php-fpm/7.3/docker-compose.yml

# 创建并启动容器
$ docker-compose up -d
```



---



## 默认对外声明

### 端口

- 9000：PHP-FPM服务端口



### 数据卷

镜像默认提供以下数据卷定义：

```shell
/var/log			# 日志输出，位于子目录 php7 中
/srv/conf			# 配置文件，位于子目录 php7 中
/srv/www			# 站点源文件
```

如果需要持久化存储相应数据，需要**在宿主机建立本地目录**，并在使用镜像初始化容器时进行映射。


举例：

- 使用宿主机`/opt/conf`存储配置文件
- 使用宿主机`/srv/data`存储数据文件
- 使用宿主机`/srv/log`存储日志文件

创建以上相应的宿主机目录后，容器启动命令中对应的映射参数类似如下：

```dockerfile
-v /host/dir/to/conf:/srv/conf -v /host/dir/to/data:/srv/data -v /host/dir/to/log:/var/log
```

> 注意：应用需要使用的子目录会自动创建。






### 容器安全

本容器默认使用`non-root`运行应用，以加强容器的安全性。在使用`non-root`用户运行容器时，相关的资源访问会受限；应用仅能操作镜像创建时指定的路径及数据。使用`non-root`方式的容器，更适合在生产环境中使用。

如果需要赋予容器内应用访问外部设备的权限，可以使用以下两种方式：

- 启动参数增加`--privileged=true`选项
- 针对特定权限需要使用`--cap-add`单独增加特定赋权，如：ALL、NET_ADMIN、NET_RAW

如果需要切换为`root`方式运行应用，可以在启动命令中增加`-u root`以指定运行的用户。



## 注意事项

- 容器中应用的启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



## 更新记录

2021/7/19:
- 7.4: 初始版本，基于 PHP 7.4.20 
- 7.3: 初始版本，基于 PHP 7.3.28 



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
