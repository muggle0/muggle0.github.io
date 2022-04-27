---
title: k8s基础
date: 2022-04-27 21:17:10
tags:
---


## Kubernetes中概念的简要概述

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


## window下搭建k8s环境





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