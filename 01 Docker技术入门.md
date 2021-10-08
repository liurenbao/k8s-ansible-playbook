# Docker技术入门

## NameSpace资源隔离

* PID - 进程编号								           内核版本：2.6.24
* NET - 网络设备、网络协议栈 端口等       内核版本：2.6.29
* IPC - 信号量、消息队列、共享内存         内核版本：2.6.19
* MOUNT - 文件系统、挂载点				    内核版本：2.4.19
* UTS - 主机名和主机域				               内核版本：2.6.19
* USER - 操作进程的用户和用户组              内核版本：3.8.X



## 什么是Docker？

Dockers是基于容器技术的轻量级虚拟化解决方案。s

Dockers是容器引擎，把Linux的cgroup、namespace等容器底层技术进行封装抽象为用户提供了创建和管理容器的便捷界面（包括命令行和API）。

![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211005115214.png)

### Docker VS VM

![img](https://i2.wp.com/www.docker.com/blog/wp-content/uploads/Blog.-Are-containers-..VM-Image-1.png?resize=700%2C298&ssl=1)

|            |                       容器技术                        |     虚拟机技术      |
| ---------- | :---------------------------------------------------: | :-----------------: |
| 占用磁盘   |             小（甚至几十KB，看镜像大小）              |  大（ISO系统文件）  |
| 启动速度   |                      快，几秒钟                       |     慢，几分钟      |
| 运行形态   | 直接运行于宿主机的内核上，不同容器共享同一个Linux内核 | 运行于Hypervisior上 |
| 并发能力   |             一台宿主机可以启动上千个容器              |  最多几十个虚拟机   |
| 性能       |                  接近宿主机本地进程                   |     逊于宿主机      |
| 资源利用率 |                          高                           |         低          |



## 安装

```
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum install epel-release -y
yum list docker --show-duplicates
yum install -y yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum list docker-ce --show-duplicates
yum install docker -y
```

镜像绝对大小和可读写部分（writable）大小有区别，每次更新都只更新的增量部分。

## Docker常用命令

### 启动容器（运行镜像）

```bash
[root@huan ~]# docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

> OPTIONS选项
>
> -i：表示启动一个可交互的容器，并持续打开标准输入
>
> -t：表示使用终端关联到容器的标准输入上输出
>
> -d：表示将容器放置后台运行
>
> -p：表示容器运行时所需要的端口号
>
> -v：表示需要将容器运行时所需要挂载到宿主机的目录
>
> --rm：退出后即删除容器
>
> --name：给容器自定义一个唯一名称，如果不指定随机生成一个名字
>
> IMAGE：表示要运行的镜像
>
> COMMAND：表示启动容器时要运行的命令

把标准输出重定向到日志

```bash
docker run hello-world 2>&1 >>/dev/null
```

查看日志，不加`-f`也可以

```bash
docker logs -f 容器镜像ID
```

删除所有退出的容器脚本

```bash
for i in `docker ps -a|grep -i exit|awk '{print $1}'`;do docker rm -f $i;done
```

打包和加载镜像

```bash
docker save 6c2009aef1cc > alpine:v3.10.3_with_1.txt.tar
docker load < alpine\:v3.10.3_with_1.txt.tar
```

其他命令参数

```
docker run -e 环境变量key:环境变量value
docker run -v 容器外目录:容器内目录
```

在容器内安装命令

```bash
tee /etc/apt/sources.list << EOF
deb http://mirrors.163.com/debian/ jessie main non-free contrib
deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib
EOF

apt-get update && apt-get install curl -y
```



## 容器生命周期

* 检查本地是否存在镜像，如果不存在即从远端仓库搜索
* 利用镜像启动容器
* 分配一个文件系统，并在只读层的镜像层外挂在一层可读写层
* 从宿主机配置的网桥接口中桥街一个虚拟接口到容器
* 从地址池配置一个IP地址给容器
* 执行用户指定的命令
* 执行完毕后容器终止

![](https://borinboy.oss-cn-shanghai.aliyuncs.com/huan/20211005114618.png)

## Docker四种网络模型

* NAT（默认）

* NONE

    docker封装的容器的业务，很有可能不对外提供网络接口。比如可能只要cpu的运算资源，内存资源，或者存储资源等，或者没有任何协议栈的要求，不对外提供http服务，或者rpc服务等。

* HOST

    HOST就是docker和宿主机在同一个网络

    ```
    docker run [OPTIONS] --net=host IMAGE [COMMAND] [ARG...]
    ```

* 联合网络

    两个容器共享一个网络名称空间

    ```
    docker run [OPTIONS] --net=container:container_id image ......
    ```

    

## Dockerfile

Docker是按照顺序执行Dockerfile里的指令集合的（从上到下依次执行）

每一个Dockerfile的第一个非注释行指令，必须是“FROM”指令，用于为镜像文件构建过程中，指定基准镜像，后续的指令运行于此基准镜像所提供的运行环境中。

### 4组Dockerfile核心指令

#### USER/WORKER指令

* user是以哪个用户身份在容器内运行
* WORKER是就是在容器中运行时所在目录

#### ADD/EXPOSE指令

- add加载宿主机文件到容器中，add指令范围更广，可以接受tar包和url
- expose指令指定哪个端口可以暴露出来

#### RUN/ENV指令

ENV是环境变量，VER是变量名（key），既可以在Dockerfile使用，也可以在docker容器中使用

RUN是在构建镜像的时候，可以执行一些可执行的命令

```bash
FROM centos:7
ENV VER 9.11.4
RUN yum install bind-$VER -y
```

#### CMD/ENTRYPOINT指令

cmd是要启动这个容器了，需要执行什么指令。

ENTRYPOINT指令，类似于cmd指令。

