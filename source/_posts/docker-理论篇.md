---
title: docker基础教程
date: 2021-08-16 10:10:22
tags: devops
---
# 认识docker
 docker是Docker.inc 公司开源的一个基于LXC技术之上构建Container容器引擎技术，Docker基于容器技术的轻量级虚拟化解决方案，实现一次交付到处运行。
 docker实现程序集装箱的概念，把我们需要交付的内容集装聚合成一个文件（镜像文件）直接交付。

# docker 基本原理

docker 架构图：
![](2022-04-24-21-43-50.png)

从架构图中我们可以看出，docker有三大核心，包括容器，仓库，镜像

- 镜像（image）：文件的层次结构，以及包含如何运行容器的元数据
- 容器（container）：容器是镜像创建的运行实例，它可以被启动、开始、停止、删除。每个容器都是相互隔离的、保证安全的平台。可以把容器看作是一个简易版的linux环境，Docker利用容器来运行应用
- 仓库（repository）：仓库是集中存放镜像文件的场所，仓库注册服务器上往往存放着多个仓库，每个仓库中又保存了很多镜像文件，每个镜像文件有着不同的标签。

 docker 具有如下特性：

- 文件系统隔离：每个进程容器运行在完全独立的根文件系统中
- 资源限制：每个进程容器运行在自己的网络命名空间中，拥有自己的虚拟接口和ip地址等
- 写时复制：由于镜像采用层式文件系统，所以采用写时复制方式创建镜像的根文件系统，这让部署变得极其快捷，并且节省内存和硬盘空间
- 日志记录：docker会收集和记录每个进程容器的标准流，用于实时检索或批量检索。不消耗本地io
- 变更管理：容器文件系统的变更可以提交到新的镜像中，并可以重复使用以创建更多容器。
- 交互式shell：docker可以分配一个虚拟终端并关联到任何容器的标准输入上。
- namespace隔离：每个进程容器运行在自己的网络命名空间里，拥有自己的虚拟接口和ip地址等

docker 工作流程图：
![](2022-04-25-10-35-10.png)

docker 工作流程大体分为三步：
- build：制作镜像，镜像如同一个集装箱，封装了包括文件，运行环境等资源
- Ship: 运输镜像，将制作好的镜像上传到仓库中，以便拉取
- Run: 运行镜像，通过镜像创建一个容器

docker容器及镜像结构：
![](2022-04-25-10-42-06.png)
Docker 支持通过扩展现有镜像，创建新的镜像，新镜像是从 base 镜像一层一层叠加生成的，每新增一个应用，就会叠加一层镜像。
镜像分层的好处就是共享资源，比如说有多个镜像都从相同的 base 镜像构建而来，那么 Docker 只需在磁盘上保存一份 base 镜像，
同时内存中也只需加载一份 base 镜像，就可以为所有容器服务了。

当容器启动时，一个新的可写层被加载到镜像的顶部，这一层通常被称作“容器层”，“容器层”之下的都叫“镜像层”。
所有对容器的添加、删除、还是修改文件都只会发生在容器层中。
只有容器层是可写的，容器层下面的所有镜像层都是只读的。

# dockers基础操作

docker 原理我们基本普及了，接下来我们进入实战环节。
接下来我们将在windows操作系统上安装docker desktop，需要注意的地方就是windows系统不能是家庭版的，需要开启虚拟化，需要安装WSL2。
具体的流程我就不介绍了，网上能找到比较多的例子

docker 安装完成之后，我们可以运行一个hello world 镜像测试：
```
docker run hello-world

```
命令行窗口输出拉取镜像运行的日志，接下来对镜像和容器进行查看删除等操作：

```
## 查看正在运行的容器
docker ps

## 查看所有容器
docker ps -a 

## 查看镜像
docker images

## 删除镜像

docker rm 容器id

## 删除镜像
docker rmi 镜像id

## 拉取远程仓库镜像
docker pull nginx

## 进入容器
docker exec -it 镜像id /bin/bash
```

# docker 实战
接下来我们创建一个springboot应用并制作成镜像，maven依赖：

```
<dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
      
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
      
  </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>com.spotify</groupId>
                <artifactId>dockerfile-maven-plugin</artifactId>
                <version>1.3.6</version>
                <configuration>
                    <repository>${project.artifactId}</repository>
                    <buildArgs>
                        <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
                    </buildArgs>
                    <tag>${project.version}</tag>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
```
然后在pom文件的同级目录下创建 Dockerfile:

```
FROM openjdk:8-jdk-alpine
ARG JAR_FILE
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```
`dockerfile-maven-plugin` 是制作镜像的maven插件，插件和build默认绑定，执行build阶段运行该插件，push绑定到deploy阶段。

而dockerfile是制作镜像的描述文件。
Dockerfile是一个文本文件，其内包含了一条条的指令(Instruction)，用于构建镜像。每一条指令构建一层镜像，因此每一条指令的内容，就是描述该层镜像应当如何构建。
Dockerfile参数说明：
![](2022-04-25-20-58-17.png)

在我们执行 `mvn package`指令时会在命令行输出整个docker镜像的制作过程，并在后续能在docker中通过docker images 查看该镜像。
制作好的镜像只是存在我们的本地中，我们可以推到远程仓库到其他机器上运行，而几大云平台都提供了免费的远程私有仓库，比如阿里云效和腾讯云coding。
后续如果有时间会出Jenkins+docker+springboot的详细教程介绍如何一键远程部署我们的应用。 

# k8s 指南


kubectl get pods -A -o wide



## 概论 

: Kubernetes中概念的简要概述

Cluster : 集群是指由Kubernetes使用一系列的物理机、虚拟机和其他基础资源来运行你的应用程序。
Node : 一个node就是一个运行着Kubernetes的物理机或虚拟机，并且pod可以在其上面被调度。.
Pod : 一个pod对应一个由相关容器和卷组成的容器组 （了解Pod详情）
Label : 一个label是一个被附加到资源上的键/值对，譬如附加到一个Pod上，为它传递一个用户自定的并且可识别的属性.Label还可以被应用来组织和选择子网中的资源（了解Label详情）
selector是一个通过匹配labels来定义资源之间关系得表达式，例如为一个负载均衡的service指定所目标Pod.（了解selector详情）
Replication Controller : replication controller 是为了保证一定数量被指定的Pod的复制品在任何时间都能正常工作.它不仅允许复制的系统易于扩展，还会处理当pod在机器在重启或发生故障的时候再次创建一个（了解Replication Controller详情）
Service : 一个service定义了访问pod的方式，就像单个固定的IP地址和与其相对应的DNS名之间的关系。（了解Service详情）
Volume: 一个volume是一个目录，可能会被容器作为未见系统的一部分来访问。（了解Volume详情）
Kubernetes volume 构建在Docker Volumes之上,并且支持添加和配置volume目录或者其他存储设备。
Secret : Secret 存储了敏感数据，例如能允许容器接收请求的权限令牌。
Name : 用户为Kubernetes中资源定义的名字
Namespace : Namespace 好比一个资源名字的前缀。它帮助不同的项目、团队或是客户可以共享cluster,例如防止相互独立的团队间出现命名冲突
Annotation : 相对于label来说可以容纳更大的键值对，它对我们来说可能是不可读的数据，只是为了存储不可识别的辅助数据，尤其是一些被工具或系统扩展用来操作的数据

## 

kubectl apply -f app.yaml

https://k8s.easydoc.net/docs/dRiQjyTY/28366845/6GiNOzyZ/puf7fjYr

https://blog.csdn.net/simongame/article/details/106727108

## window下搭建k8s环境

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

## namespace
命名空间在k8s中的主要作用是资源隔离，可以将多个 pod 放入同一namespace中，实现对一组pod资源的管理。
k8s 在集群启动后，会默认创建几个namespace ,可以通过指令`kubectl get ns` 查看：

```
C:\Users\Administrator>kubectl get ns
NAME                   STATUS   AGE
default                Active   34d
kube-node-lease        Active   34d
kube-public            Active   34d
kube-system            Active   34d
kubernetes-dashboard   Active   34d

```

如果我们创建pod的时候未指定namespace,则会默认划分到 default 命名空间中，`kube-node-lease` 用于维护节点之间的心跳，`kube-public` 公共资源的命名空间，可以被所有人访问，`kube-system` k8s的系统资源命名空间。
查看命名空间指令：
```
kubectl get pods -n kube-system 

### 控制台返回

NAME                                     READY   STATUS    RESTARTS         AGE
coredns-78fcd69978-7df2r                 1/1     Running   41 (18m ago)     34d
coredns-78fcd69978-cwwmp                 1/1     Running   41 (18m ago)     34d
etcd-docker-desktop                      1/1     Running   41 (18m ago)     34d
kube-apiserver-docker-desktop            1/1     Running   41 (18m ago)     34d
kube-controller-manager-docker-desktop   1/1     Running   41 (18m ago)     34d
kube-proxy-5hfwt                         1/1     Running   41 (18m ago)     34d
kube-scheduler-docker-desktop            1/1     Running   41 (18m ago)     34d
storage-provisioner                      1/1     Running   81 (17m ago)     34d
vpnkit-controller                        1/1     Running   1728 (17m ago)   34d

```

namespace 相关指令：

```
### 查看 
kubectl get ns

### 查看某一个
kubectl get ns default

### 查看详情 
kubectl describe ns default

### 创建
kubectl create ns dev

### 删除 
kubectl delete ns dev

```
在namespace 属性中 status 的状态包括 active Terminating（正在删除），resource quota 属性限制了 ns的资源，limitRange resource 限制了 ns 下 pod的资源

我们还可以以配置文件的形式创建namespace，创建ns-dev.yaml:

```
apiVersion: v1
kind: Namespace
metadata:
  name: dev

```
执行对应的创建或删除命令：

```
kubectl create -f ns-dev.yaml
kubectl delete -f ns-dev.yaml

```


## pod

pod 是k8s集群进行部署管理的最小单元，一个pod中可以有一个或者多个容器，pod是对容器的封装。k8s 在集群启动后，集群中的各个组件都是以pod的方式运行的。可以通过以下命令查看：

```
kubectl get pod -n kube-system [-o wide]

### 控制台返回
C:\Users\Administrator>kubectl get pod -n kube-system
NAME                                     READY   STATUS    RESTARTS           AGE
coredns-78fcd69978-7df2r                 1/1     Running   43 (70m ago)       35d
coredns-78fcd69978-cwwmp                 1/1     Running   43 (70m ago)       35d
etcd-docker-desktop                      1/1     Running   43 (70m ago)       35d
kube-apiserver-docker-desktop            1/1     Running   43 (70m ago)       35d
kube-controller-manager-docker-desktop   1/1     Running   43 (70m ago)       35d
kube-proxy-5hfwt                         1/1     Running   43 (70m ago)       35d
kube-scheduler-docker-desktop            1/1     Running   43 (70m ago)       35d
storage-provisioner                      1/1     Running   85 (69m ago)       35d
vpnkit-controller                        1/1     Running   1770 (9m43s ago)   35d

```

pod相关指令：

```
### 运行一个pod 
kubectl run nginx --image=nginx:1.17.1 --port=80 --namespace dev

### 查看
kubectl get pod -n kube-system -o wide
kubectl describe pod nginx-xxxx -n dev

## 删除
kubectl delete pod nginx-xxxx -n dev

## 删除pod 控制器 当pod 绑定pod 控制器的时候，直接删除pod后，pod控制器会重建pod 因此需要删除对应的pod控制器
kubectl get deployment -n dev

### 删除pod 控制器
kubectl delete deployment nginx -n dev

```

通过配置文件创建pod:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: dev
spec:
  containers:
  - image: nginx:latest
    name: pod
    ports:
    - name: nginx-port
      containerPort: 80
      protocol: TCP
```

然后就可以执行对应的创建和删除命令了：

创建：kubectl create -f pod-nginx.yaml

删除：kubectl delete -f pod-nginx.yaml

## label

Label是kubernetes系统中的一个重要概念。它的作用就是在资源上添加标识，用来对它们进行区分和选择。

Label的特点：

- 一个Label会以key/value键值对的形式附加到各种对象上，如Node、Pod、Service等等
- 一个资源对象可以定义任意数量的Label ，同一个Label也可以被添加到任意数量的资源对象上去
- Label通常在资源对象定义时确定，当然也可以在对象创建后动态添加或者删除

可以通过Label实现资源的多维度分组，以便灵活、方便地进行资源分配、调度、配置、部署等管理工作。

> 一些常用的Label 示例如下：
>
> - 版本标签："version":"release", "version":"stable"......
> - 环境标签："environment":"dev"，"environment":"test"，"environment":"pro"
> - 架构标签："tier":"frontend"，"tier":"backend"


打标签命令
```
kubectl get pod -n dev --show-labels
kubectl label pod nginx -n dev version=1.0 
kubectl label pod nginx -n dev version=2.0 --overwrite
kubectl label pod -l "version=2.0" -n dev

## 删除标签 
kubectl label pod nginx -n dev version-

# pod 更新
kubectl apply -f nginx.yaml
```

配置文件打标签

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: dev
  labels:
    version: "3.0" 
    env: "test"
spec:
  containers:
  - image: nginx:latest
    name: pod
    ports:
    - name: nginx-port
      containerPort: 80
      protocol: TCP
```

在pod的yaml 中指定标签然后通过指令：
```
kubectl apply -f nginx.yaml
```
完成更新


## deployment


在kubernetes中，Pod是最小的控制单元，但是kubernetes很少直接控制Pod，一般都是通过Pod控制器来完成的。Pod控制器用于pod的管理，确保pod资源符合预期的状态，当pod的资源出现故障时，会尝试进行重启或重建pod。

在kubernetes中Pod控制器的种类有很多，本章节只介绍一种：Deployment。

```
## 查看deployment pod
kubectl get deployment,pods -n dev
# 命令格式: kubectl create deployment 名称  [参数] 
# --image  指定pod的镜像
# --port   指定端口
# --replicas  指定创建pod数量
# --namespace  指定namespace
[root@master ~]# kubectl run nginx --image=nginx:latest --port=80 --replicas=3 -n dev
deployment.apps/nginx created

# 查看创建的Pod
[root@master ~]# kubectl get pods -n dev
NAME                     READY   STATUS    RESTARTS   AGE
nginx-5ff7956ff6-6k8cb   1/1     Running   0          19s
nginx-5ff7956ff6-jxfjt   1/1     Running   0          19s
nginx-5ff7956ff6-v6jqw   1/1     Running   0          19s

# 查看deployment的信息
[root@master ~]# kubectl get deploy -n dev
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   3/3     3            3           2m42s

# UP-TO-DATE：成功升级的副本数量
# AVAILABLE：可用副本的数量
[root@master ~]# kubectl get deploy -n dev -o wide
NAME    READY UP-TO-DATE  AVAILABLE   AGE     CONTAINERS   IMAGES              SELECTOR
nginx   3/3     3         3           2m51s   nginx        nginx:latest        run=nginx

# 查看deployment的详细信息
[root@master ~]# kubectl describe deploy nginx -n dev
Name:                   nginx
Namespace:              dev
CreationTimestamp:      Wed, 08 May 2021 11:14:14 +0800
Labels:                 run=nginx
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               run=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  run=nginx
  Containers:
   nginx:
    Image:        nginx:latest
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-5ff7956ff6 (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  5m43s  deployment-controller  Scaled up replicaset nginx-5ff7956ff6 to 3
  
# 删除 
[root@master ~]# kubectl delete deploy nginx -n dev
deployment.apps "nginx" deleted
```

配置文件创建：
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: dev
spec:
  replicas: 3
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - image: nginx:latest
        name: nginx
        ports:
        - containerPort: 80
          protocol: TCP
```

## service
通过上节课的学习，已经能够利用Deployment来创建一组Pod来提供具有高可用性的服务。

虽然每个Pod都会分配一个单独的Pod IP，然而却存在如下两问题：

- Pod IP 会随着Pod的重建产生变化
- Pod IP 仅仅是集群内可见的虚拟IP，外部无法访问

这样对于访问这个服务带来了难度。因此，kubernetes设计了Service来解决这个问题。

Service可以看作是一组同类Pod**对外的访问接口**。借助Service，应用可以方便地实现服务发现和负载均衡。


```
# 暴露Service
[root@master ~]# kubectl expose deploy nginx --name=svc-nginx1 --type=ClusterIP --port=80 --target-port=80 -n dev
service/svc-nginx1 exposed

# 查看service
[root@master ~]# kubectl get svc svc-nginx1 -n dev -o wide
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE     SELECTOR
svc-nginx1   ClusterIP   10.109.179.231   <none>        80/TCP    3m51s   run=nginx

```
https://www.bilibili.com/video/BV1Qv41167ck?p=19