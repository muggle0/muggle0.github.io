---
title: springcloud核心组件介绍
date: 2019-04-26 11:30:45
tags: cloud
---

作者：muggle

注：参考大佬博客[牧码小子](https://mp.weixin.qq.com/s?__biz=MzI1NDY0MTkzNQ==&mid=2247483878&idx=1&sn=d49f2eb61bada3d34443a0a4017a7b72&scene=21#wechat_redirect) 

### springcloud的核心功能：

> 负载均衡，服务注册与发现，监控，分布式配置管理，api网关 分布式追踪

<!--more-->

###  SpringCloudGateway：

> Spring Cloud Gateway是Spring官方基于Spring 5.0，Spring Boot 2.0和Project Reactor等技术开发的网关，Spring Cloud Gateway旨在为微服务架构提供一种简单而有效的统一的API路由管理方式。Spring Cloud Gateway作为Spring Cloud生态系中的网关，目标是替代Netflix ZUUL，其不仅提供统一的路由方式，并且基于Filter链的方式提供了网关基本的功能，例如：安全，监控/埋点，和限流等。

### SpringCloudNetflix

> 包含组件有Netflix Eureka，Netflix Hystrix，Netflix Zuul等

### SpringCloudConfig

> 配置中心，配置管理工具包，让你可以把配置放到远程服务器，集中化管理集群配置，目前支持本地存储、Git以及Subversion。

### SpringCloudBus

> Spring Cloud Bus 将分布式的节点用轻量的消息代理连接起来。它可以用于广播配置文件的更改或者服务之间的通讯，也可以用于监控

### SpringCloudforCloudFoundry

> Spring Cloud for Cloudfoundry可以轻松在Cloud Foundry（平台即服务）中运行Spring Cloud应用程序。 Cloud Foundry有一个“服务”的概念，它是“绑定”到应用程序的中间件，本质上为其提供包含凭据的环境变量（例如，用于服务的位置和用户名）。——不太明白这玩意

### SpringCloudCluster

> Spring Cloud Cluster将取代Spring Integration。提供在分布式系统中的集群所需要的基础功能支持，如：选举、集群的状态一致性、全局锁、tokens等常见状态模式的抽象和实现。

### SpringCloudConsul

> Consul是一个支持多数据中心分布式高可用的服务发现和配置共享的服务软件,由 HashiCorp 公司用 Go 语言开发, 基于 Mozilla Public License 2.0 的协议进行开源. Consul 支持健康检查,并允许 HTTP 和 DNS 协议调用 API 存储键值对.
> Spring Cloud Consul封装了Consul操作，consul是一个服务发现与配置工具，与Docker容器可以无缝集成。

### Spring Cloud Security

> 安全框架

### Spring Cloud Sleuth

> 日志收集工具包，封装了Dapper和log-based追踪以及Zipkin和HTrace操作，为SpringCloud应用实现了一种分布式追踪解决方案。

还有其他组件，不再罗列