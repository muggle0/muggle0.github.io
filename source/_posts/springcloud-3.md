---
title: springCloud学习笔记——配置高可用Eureka
date: 2019-04-27 10:02:18
tags: cloud
---

# CAP 定理

> 原文链接 http://www.ruanyifeng.com/blog/2018/07/cap.html<br>
>  分布式系统的最大难点，就是各个节点的状态如何同步。CAP 定理是这方面的基本定理，也是理解分布式系统的起点。

- Consistency 中文叫做"一致性"。意思是，写操作之后的读操作，必须返回该值。
- Availability Availability 中文叫做"可用性"，意思是只要收到用户的请求，服务器就必须给出回应。
- Partition tolerance 中文叫做"分区容错"。大多数分布式系统都分布在多个子网络。每个子网络就叫做一个区（partition）。分区容错的意思是，区间通信可能失败。

 这三个指标不可能同时做到，一般来说，分区容错无法避免，因此可以认为 CAP 的 P 总是成立。CAP 定理告诉我们，剩下的 C 和 A 无法同时做到。对于Eureka而言，其是满足AP的。

<!--more-->

# Eureka特性：
> - 优先保证可用性

- 各个节点都是平等的，几个节点挂掉不会影响正常节点的工作，剩余的节点依然可以提供注册和查询服务
- 在向某个Eureka注册时如果发现连接失败，则会自动切换至其它节点，只要有一台Eureka还在，就能保证注册服务可用(保证可用性)，只不过查到的信息可能不是最新的(不保证强一致性)

# Eureka的高可用:

Eureka Server可以运行多个实例来构建集群，解决单点问题，Eureka Server采用的是Peer to Peer对等通信。这是一种去中心化的架构，无master/slave区分，每一个Peer都是对等的。在这种架构中，节点通过彼此互相注册来提高可用性，每个节点需要添加一个或多个有效的serviceUrl指向其他节点。每个节点都可被视为其他节点的副本。

如果某台Eureka Server宕机，Eureka Client的请求会自动切换到新的Eureka Server节点，当宕机的服务器重新恢复后，Eureka会再次将其纳入到服务器集群管理之中。当节点开始接受客户端请求时，所有的操作都会进行replicateToPeer（节点间复制）操作，将请求复制到其他Eureka Server当前所知的所有节点中。

Eureka Server的高可用，实际上就是将自己也作为服务向其他服务注册中心进行注册，这样就可以形成一组相互注册的服务注册中心，以实现服务清单的互相同步，达到高可用的效果。

通过点对点配置，Eureka注册中心通过相互注册来实现高可用配置。以下构建一个双节点的集群模式。

1.创建一个application-tran.properties配置文件，同时修改application.properties文件。修改本地的hosts文件
增加两个域名

```java
127.0.0.1 test1
127.0.0.1 test2
```

application-tran.properties:

```java
spring.application.name=eureka-service
# 修改端口
server.port=8181

# 实例名称 两个名称需要不一样 值为域名或者ip
eureka.instance.hostname=test2

## 不要向注册中心注册自己
eureka.client.register-with-eureka=false
## 表示不去检索其他的服务，因为服务注册中心本身的职责就是维护服务实例，它也不需要去检索其他服务
eureka.client.fetch-registry=false

# 指定服务注册中心地址
eureka.client.service-url.defaultZone=http://test1:8180/eureka

```

application.properties:

```java
spring.application.name=eureka-service
server.port=8180
# 实例名称 两个名称需要不一样 值为域名或者ip
eureka.instance.hostname=test1
eureka.client.register-with-eureka=false
eureka.client.fetch-registry=false
eureka.client.service-url.defaultZone=http://test2:8181/eureka
```

使用spring.profiles.active特性来启动注册中心，spring.profiles.active相关知识这里不做介绍，第一个注册中心启动时会报错，等另外一个启动成功就正常了。
而向注册中心注册服务只需改一个地方

```java
eureka.client.service-url.defaultZone=http://test1:8180/eureka,http://test2:8181/eureka
```

也可只注册到某个节点上，其他的节点也会有此服务列表的，一般建议以集群方式进行配置，即多注册中心配置。避免单点故障，Eureka在搜索注册中心时，根据defaultZone列表，找到一个可用的，之后就不会继续去下一个注册中心地址拉取服务列表了，此时若其中一个注册中心挂了，这个时候客户端会继续去第二个注册中心拉取服务列表的。