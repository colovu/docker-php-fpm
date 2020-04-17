# PHP-FPM Alpine
基于的 Alpine 系统的 Docker 镜像，用于提供 PHP-FPM 服务。




## 基本信息

* 镜像地址：endial/php-fpm-alpine:v5
* 依赖镜像：endial/alpine:v3.11



## 数据卷

```
/var/log			# 日志输出，位于子目录 php5 中
/srv/conf			# 配置文件，位于子目录 php5 中
/srv/www			# 站点源文件
```



## 使用说明

生成并运行一个新的容器：

```
 docker run -d --name php-fpm \
  -v /srv/www:/srv/www \
  -v /srv/conf:/srv/conf \
  endial/php-fpm-alpine:v5
```

如果存在 dvc（endial/dvc-alpine） 数据卷容器：

```
docker run -d --name php-fpm \
  --volumes-from dvc \
  endial/php-fpm-alpine:v5
```



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com)
