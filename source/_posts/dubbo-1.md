---
title: dubbo学习笔记
date: 2019-04-26 17:29:58
tags: cloud
---

dubbo 架构介绍

注册中心 服务提供者 消费者 管理者 容器

registry provider consumer monitor container

<!--more-->

# dubbo 环境搭建 

## 安装zk

conf文件下创建 zoo.cfg

配置dataDir 

bin下zkServer zkCli

测试  

```shell
get / 
ls /
create -e /test 123456
get /test
```

安装监控中心 下载 <https://github.com/apache/incubator-dubbo-admin/tree/master> 切换到master分支

打 jar包

## 项目构建

dubbo版本问题

dubbo 2.6以前是阿里巴巴 dubbo

因此 dubbo 的dubbo-spring-boot-starter存在两个对应的版本 

官方是这样说的：

> 如果您现在使用的Dubbo版本低于2.7.0，请使用如下对应版本的Dubbo Spring Boot：
>
> | Dubbo Spring Boot                                            | Dubbo  | Spring Boot |
> | ------------------------------------------------------------ | ------ | ----------- |
> | [0.2.1.RELEASE](https://github.com/apache/incubator-dubbo-spring-boot-project/tree/0.2.x) | 2.6.5+ | 2.x         |
> | [0.1.2.RELEASE](https://github.com/apache/incubator-dubbo-spring-boot-project/tree/0.1.x) | 2.6.5+ | 1.x         |
>
> 

其实就是如果用 阿里巴巴dubbo 则需要使用

```xml
<dependency>
    <groupId>com.alibaba.boot</groupId>
    <artifactId>dubbo-spring-boot-starter</artifactId>
</dependency>
```

这个starter

如果是 鸟毛dubbo则

```xml
<dependency>
    <groupId>org.apache.dubbo</groupId>
    <artifactId>dubbo-spring-boot-starter</artifactId>
</dependency>
```

alibaba 0.2的stater配置

```properties
#  服务名
dubbo.application.name=demo-provider
# 注册中心地址
dubbo.registry.address=zookeeper://127.0.0.1:2181
dubbo.protocol.name=dubbo
dubbo.protocol.port=20880
dubbo.provider.timeout=10000
dubbo.provider.retries=3
dubbo.provider.delay=-1
server.port=8082
```

alibaba 2的 stater的配置

```properties
spring.dubbo.application.id=live-dubbo-provider
spring.dubbo.application.name=live-dubbo-provider
spring.dubbo.registry.address=zookeeper://127.0.0.1:2181
spring.dubbo.server=true
spring.dubbo.protocol.name=dubbo
spring.dubbo.protocol.port=20880
server.port=8081
```

需要引入zk客户端依赖：com.101tec 和curator-framework

这里不介绍鸟毛的dubbo配置，在nacos整合dubbo中说明

## 监控中心

[dubbo-monitor-simple](https://github.com/apache/incubator-dubbo-admin/tree/master/dubbo-monitor-simple)

# dubbo架构

[dubbo架构图](<http://dubbo.apache.org/zh-cn/docs/dev/design.html>)

dubbo 绑定端口，通道初始化，注册到选择器上 选择器监听 acccept事件

处理数据 客户端生成channel 

business

​		接口

rpc

​	配置层 收集配置数据

​	服务代理层 代理调用方法

​	registry 注册中心

​	cluster 路由层 负载均衡层

​	moniter 监控层 

​	protocol远程调用层

​	调用层核心  invoker protocol  exporter

remothing 远程通信层 ，架起管道 封装数据。netty框架工作在这

serialize 序列化层



