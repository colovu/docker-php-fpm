# PHP-FPM

针对PHP 应用的 Docker 镜像，用于提供 PHP解析及PHP-FPM 服务。




## 基本信息

* 镜像地址：endial/php:v7.2
  * 依赖镜像：endial/ubuntu:v18.04



## 数据卷

镜像默认提供以下数据卷定义：

```shell
/var/log			# 日志输出，位于子目录 php7 中
/srv/conf			# 配置文件，位于子目录 php7 中
/srv/www			# 站点源文件
```

如果需要持久化存储相应数据，需要在宿主机建立本地目录，并在使用镜像初始化容器时进行映射。

举例：

- 使用宿主机`/opt/conf`存储配置文件
- 使用宿主机`/srv/data`存储数据文件
- 使用宿主机`/srv/log`存储日志文件

创建以上相应的宿主机目录后，容器启动命令中对应的映射参数类似如下：

```dockerfile
-v /host/dir/to/conf:/srv/conf -v /host/dir/to/data:/srv/data -v /host/dir/to/log:/var/log
```

> 注意：应用需要使用的子目录会自动创建。



## 使用说明



### 运行容器

生成并运行一个新的容器：

```shell
 docker run -d --name php-fpm \
  -v /host/dir/to/www:/srv/www:ro \
  -v /host/dir/to/conf:/srv/conf \
  endial/php:v7.2
```

如果存在 dvc（endial/dvc-alpine） 数据卷容器：

```shell
docker run -d --name php-fpm \
  --volumes-from dvc \
  endial/php:v7.2
```



### 进入容器

使用容器ID或启动时的命名（本例中命名为`php-fpm`）进入容器：

```shell
docker exec -it php-fpm /bin/bash
```



### 停止容器

使用容器ID或启动时的命名（本例中命名为`php-fpm`）停止：

```shell
docker stop php-fpm
```



## 注意事项

- 容器中启动参数不能配置为后台运行，只能使用前台运行方式，即：`daemonize no`
- 如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com)
