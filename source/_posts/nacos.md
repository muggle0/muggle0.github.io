---
title: 服务注册发现与配置中心新选择——nacos
date: 2019-04-27 10:17:48
tags: cloud
---

### 编辑中



# nacos简介

​	在nacos-0.3的时候我就开始关注，期间还写过一篇作为springcloud配置中心的使用记录的博客。在前不久，nacos终于出了正式版，赶个时髦出篇博客吹一波，[nacos官方文档](https://nacos.io/zh-cn/index.html)

<!--more-->

## nacos特性

###  服务发现和服务健康监测

支持基于 DNS 和基于 RPC 的服务发现（**可替代eureka**）。Nacos 提供对服务的实时的健康检查，阻止向不健康的主机或服务实例发送请求。Nacos 支持传输层 (PING 或 TCP)和应用层 (如 HTTP、MySQL、用户自定义）的健康检查。 对于复杂的云环境和网络拓扑环境中（如 VPC、边缘网络等）服务的健康检查，Nacos 提供了 agent 上报模式和服务端主动检测2种健康检查模式。Nacos 还提供了统一的健康检查仪表盘，帮助您根据健康状态管理服务的可用性及流量。

### 动态配置服务

动态配置服务可以让您以中心化、外部化和动态化的方式管理所有环境的应用配置和服务配置（**可以作为配置中心**）。动态配置消除了配置变更时重新部署应用和服务的需要，让配置管理变得更加高效和敏捷。配置中心化管理让实现无状态服务变得更简单，让服务按需弹性扩展变得更容易。Nacos 提供了一个简洁易用的UI ([控制台样例 Demo](http://console.nacos.io/nacos/index.html)) 帮助您管理所有的服务和应用的配置。Nacos 还提供包括配置版本跟踪、金丝雀发布、一键回滚配置以及客户端配置更新状态跟踪在内的一系列开箱即用的配置管理特性，帮助您更安全地在生产环境中管理配置变更和降低配置变更带来的风险。

### 动态 DNS 服务

动态 DNS 服务支持权重路由，让您更容易地实现中间层负载均衡、更灵活的路由策略、流量控制以及数据中心内网的简单DNS解析服务（**可做负载均衡**）。动态DNS服务还能让您更容易地实现以 DNS 协议为基础的服务发现，以帮助您消除耦合到厂商私有服务发现 API 上的风险。

### 服务及其元数据管理

Nacos 能让您从微服务平台建设的视角管理数据中心的所有服务及元数据，包括管理服务的描述、生命周期、服务的静态依赖分析、服务的健康状态、服务的流量管理、路由及安全策略、服务的 SLA 以及最首要的 metrics 统计数据（**不知道啥意思，以后研究**）。

## nacos的相关概念

- 地域 （Region）：物理的数据中心，资源创建成功后不能更换。
- 可用区（Available Zone）：同一地域内，电力和网络互相独立的物理区域。同一可用区内，实例的网络延迟较低。
- 接入点（Endpoint）：地域的某个服务的入口域名。
- 命名空间（Namespace）：用于进行租户粒度的配置隔离。不同的命名空间下，可以存在相同的 Group 或 Data ID 的配置。Namespace 的常用场景之一是不同环境的配置的区分隔离，例如开发测试环境和生产环境的资源（如配置、服务）隔离等。
- 元信息(Metadata)：Nacos数据（如配置和服务）描述信息，如服务版本、权重、容灾策略、负载均衡策略、鉴权配置、各种自定义标签 (label)，从作用范围来看，分为服务级别的元信息、集群的元信息及实例的元信息。
- 实例（Instance）：提供一个或多个服务的具有可访问网络地址（IP:Port）的进程。
- 权重（Weight）：实例级别的配置。权重为浮点数。权重越大，分配给该实例的流量越大。
- 健康检测（Health Check）：以指定方式检查服务下挂载的实例 (Instance) 的健康度，从而确认该实例 (Instance) 是否能提供服务。根据检查结果，实例 (Instance) 会被判断为健康或不健康。对服务发起解析请求时，不健康的实例 (Instance) 不会返回给客户端。
- 健康保护阈值（Protect Threshold）：为了防止因过多实例 (Instance) 不健康导致流量全部流向健康实例 (Instance) ，继而造成流量压力把健康 健康实例 (Instance) 压垮并形成雪崩效应，应将健康保护阈值定义为一个 0 到 1 之间的浮点数。当域名健康实例 (Instance) 占总服务实例 (Instance) 的比例小于该值时，无论实例 (Instance) 是否健康，都会将这个实例 (Instance) 返回给客户端。这样做虽然损失了一部分流量，但是保证了集群的剩余健康实例 (Instance) 能正常工作。
- 服务分组（Service Group）：不同的服务可以归类到同一分组。
- 虚拟集群（Virtual Cluster）：同一个服务下的所有服务实例组成一个默认集群, 集群可以被进一步按需求划分，划分的单位可以是虚拟集群。

# nacos 使用

## 安装

可在github上下载安装包安装，或者采用docker安装；

windows上运行：[nacos github地址](<https://github.com/alibaba/nacos>) 在github查看该项目的releases并下载最新版，解压后进入bin目录 运行`startup.cmd`。

docker上运行：docker run --name nacos-standalone -e MODE=standalone -p 8848:8848 nacos/nacos-server:latest 可运行一个单机版nacos

浏览器上访问 ip:8848/nacos 进入登陆界面，用户名和密码都是nacos；登陆成功就能看到控制台UI界面了。在安装包的./conf目录下有一个application.properties文件，这是nacos的配置文件，相关配置后期会说。

## 作为配置中心

### 示例

这里为方便讲解，我们现在Windows环境下运行一个单机版nacos，启动后登陆；创建一个springboot应用，导入依赖

```xml
 <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-alibaba-nacos-config</artifactId>
    <version>0.9.0.RELEASE</version>
 </dependency>
```

然后删除application.properties 新建一个bootstrap.properties。这里可能还有同学不知道application和bootstrap的区别；在这里科普一下：在 Spring Boot 中有两种上下文，一种是 bootstrap, 另外一种是 application, bootstrap 是应用程序的父上下文，也就是说 bootstrap 加载优先于 applicaton。bootstrap 主要用于从额外的资源来加载配置信息，还可以在本地外部配置文件中解密属性。这两个上下文共用一个环境，它是任何Spring应用程序的外部属性的来源。bootstrap 里面的属性会优先加载，它们默认也不能被本地相同配置覆盖。bootstrap比application要先加载，bootstrap只在cloud项目中使用。

添加配置：

```properties
#服务名
spring.application.name=nacos-config-example
# 配置中心url
spring.cloud.nacos.config.server-addr=127.0.0.1:8848
# 配置中心的配置语法
spring.cloud.nacos.config.file-extension=properties
```

现在在nacos配置中心新建配置：

dataId:nacos-config-example.properties

![1556523308515](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1556523308515.png)

启动项目，发现项目端口号是8082，我们的配置成功了。

### 说明

注意 图中几个选项 TEXT\JSON\ XML \YAML\ HTML\Propertiest这些并不是指定nacos以何种语法去解析配置文件，仅仅是提供语法提示，代码高亮辅助样式；第一次使用的人很容易被误导。我们要指定配置文件语法要在bootstrap做如下配置：

```properties
spring.cloud.nacos.config.file-extension=properties
spring.cloud.nacos.config.file-extension=yaml
```

配置中心配置依靠dataId将配置信息和客户端绑定，我们来看看dataId组成规则：

```java
${prefix}-${spring.profile.active}.${file-extension}
```

- `prefix` 默认为 `spring.application.name` 的值，也可以通过配置项 `spring.cloud.nacos.config.prefix`来配置。

- `spring.profile.active` 即为当前环境对应的 profile， **注意：当 spring.profile.active 为空时，对应的连接符 - 也将不存在，dataId 的拼接格式变成 ${prefix}.${file-extension}**
- `file-exetension` 为配置内容的数据格式，可以通过配置项 `spring.cloud.nacos.config.file-extension` 来配置。目前只支持 `properties` 和 `yaml` 类型。

也就是说我们这个配置中心的dataId和我们平时用springboot命名配置文件只有一个prefix的区别

现在我们来修改一下配置文件，bootstrap加一项：

```properties
spring.cloud.nacos.config.prefix=config-test
spring.profiles.active=dev
```

配置中心弄两个配置方便比较，一个dataId是`config-test-dev.properties`，一个dataId是`config-test-prod.properties`配置端口号分别为8081和8082测试。启动项目后发现项目端口号为8081，然后修改配置重启：

```properties
spring.profiles.active=prod
```

此时端口变成了8082。用法和springboot的配置文件区别不大。

### 命名空间和分组

命名空间和分组相当于一个配置文件的"年级和班次"，在同一个group下，配置文件名不能重复，所以当需要创建文件名称相同的两个配置文件时，将两个配置文件创建在不同的group下即可。而namespace范围比group大，目的是一样的。

定义命名空间方式如图

![1556525537769](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1556525537769.png)

在bootstrap中对应配置

```properties
spring.cloud.nacos.config.namespace=命名空间ID
```

分组则在配置中心新建配置的时候可指定，在bootstrap中对应配置

```properties
spring.cloud.nacos.config.group=group
```

### 配置自动更新

通过 Spring Cloud 原生注解 `@RefreshScope` 实现配置自动更新，示例：

```java
@Service
@RefreshScope
public class ConfigController {

    @Value("${config.test}")
    private String test;
	public void testStr(){
        System.out.print(test)
    }
    
}
```

当你在配置中心更新`config.test`的 客户端的test的值也会刷新，并且你还能在客户端看到值变更的相关日志。

### 小结

别的不说，这比spring cloud config好用太多了有木有，和apollo比起来配置太容易了有木有；这么好用的东西，出正式版了，等坑都排完了妥妥的神器有木有。我选nacos，你呢。

## 作为注册中心

### 介绍

在分布式系统中，我们不仅仅是需要在注册中心找到服务和映射服务地址，我们还需要考虑更多更复杂的问题：服务注册后，如何被及时发现，服务宕机后，如何及时下线，服务异常时，如何进行降级。这便是注册中心存在的意义