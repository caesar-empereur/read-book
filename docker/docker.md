## docker 常见命令

- docker 镜像，容器，仓库的关系

    - 镜像 : 就相当于是一个 root 文件系统。
比如官方镜像 ubuntu:16.04 就包含了完整的一套 Ubuntu16.04 最小系统的 root 文件系统。

    - 容器 : 镜像和容器的关系，就像是面向对象程序设计中的类和实例一样，
镜像是静态的定义，容器是镜像运行时的实体。容器可以被创建、启动、停止、删除、暂停等。

    - 仓库 : 仓库可看成一个代码控制中心，用来保存镜像。

```
镜像类似 类，容器类似类创建的实例对象，仓库类似代码存放的地方
```

- docker search mysql 搜索镜像
- docker pull mysql 拉取镜像
- docker run -it ubuntu /bin/bash
```
-i: 交互式操作。
-t: 终端。
ubuntu: ubuntu 镜像。
/bin/bash：放在镜像名后的是命令，这里我们希望有个交互式 Shell，因此用的是 /bin/bash。
要退出终端，直接输入 exit:
```
- docker images (查看安装的镜像)
- docker ps (查看所有的运行的容器)
- docker start 容器id
- docker stop  容器id
- docker rm 容器id
- docker run 命令
```
docker run --name 容器名称 -p 3307:3306
3307 对应的是宿主机的端口，也就是物理机的端口，3306 对应的是容器的端口
```
- docker logs 容器id （查看一个容器输出的错误日志）

- docker 运行mysql 容器的弊端就是容器一旦停止，数据库的数据默认是没有持久化的
- docker inspect 容器id (查看一个容器的 网络配置,容器本身的ip是多少)

## Dockerfile

```
FROM java:8
ADD vue-admin-server.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```
- Dockerfile 是一个用来构建私有镜像的文本文件，文本内容包含了一条条构建镜像所需的指令和说明
- FROM：定制的镜像都是基于 FROM 的镜像
- ADD 把当前路径的文件添加到容器中
- EXPOSE 暴露容器的指定端口
- ENTRYPOINT 容器实际运行的命令
- docker build -t 镜像名称 . (构建镜像)
- 构建完镜像后 docker images 查看是否已经构建成功
- docker run -d -p 8080:8085 镜像名称 (指定端口映射的方式来启动容器)
- docker run --net=host 镜像名称  (使用与宿主机一样的网络来启动容器)

## docker 容器与宿主机的网络
- Docker提供几种网络类型，常见的有 bridge，host
    - bridge
    ```
    Bridge是Docker默认使用的网络类型。如图，网络中的所有容器可以通过IP互相访问。
    Bridge网络通过网络接口docker0 与主机桥接，
    可以在主机上通过ifconfig docker0查看到该网络接口的信息
    ```
    - host
    ```
    Host模式下，容器的网络接口不与宿主机网络隔离。容器与宿主机使用相同的网络，
    在容器中监听相应端口的应用能够直接被从宿主机访问。host网络仅支持Linux
    ```

## docker compose
