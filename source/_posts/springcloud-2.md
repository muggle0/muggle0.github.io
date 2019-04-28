---
title: springcloud-Eureka
date: 2019-04-26 11:34:15
tags: cloud
---

作者：muggle

### 服务治理

 服务治理是微服务架构中最为核心和基础的模块。它主要用来实现各个微服务实例的自动化注册与发现。随着服务的越来越多，越来越杂，服务之间的调用会越来越复杂，越来越难以管理。而当某个服务发生了变化，或者由于压力性能问题，多部署了几台服务，怎么让服务的消费者知晓变化，就显得很重要了。不然就会存在调用的服务其实已经下线了，但调用者不知道等异常情况。这个时候有个服务组件去统一治理就相当重要了。Eureka便是服务治理的组件。

<!--more-->

### Eureka介绍

 Eureka包含Server和Client两部分。Server也称为注册中心，用于提供服务的注册与发现（服务注册是指微服务在启动时，将自己的信息注册到服务治理组件上的过程，服务发现是指查询可用微服务列表及其网络地址的机制。）。支持高可用配置，依托与强一致性提供良好的服务实例可用性，可以应对多种不同的故障场景。

 Client主要处理服务的注册与发现；客户端服务通过注解和参数配置方式，嵌入在客户端的应用程序代码中，在应用程序启动时，向注册中心注册自身提供的服务并周期性地发送心跳来更新它的服务租约。同时，它也能从服务端查询当前注册的服务信息并把它们缓存到本地并周期性地刷新服务状态。

### 创建Eureka服务端

1.创建一个springboot工程，导入依赖：

```java
<dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>

```

2.配置

```java
spring.application.name=eureka-service
# 修改端口
server.port=8180

# 实例的主机名称
eureka.instance.hostname=localhost

## 不要向注册中心注册自己
eureka.client.register-with-eureka=false
## 表示不去检索其他的服务，因为服务注册中心本身的职责就是维护服务实例，它也不需要去检索其他服务
eureka.client.fetch-registry=false

# 指定服务注册中心地址 这里直接指向了本服务 localhost:8180/eureka/
# map对象，使用IDE的提示功能是不会出现 注意大小写
eureka.client.service-url.defaultZone=http://${eureka.instance.hostname}:${server.port}/eureka/

```

3.启动类上添加注解@EnableEurekaServer

```java
EnableEurekaServer
@SpringBootApplication
public class SpringcloudApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringcloudApplication.class, args);
    }
}
```

启动项目后访问 http://localhost:8180/ 就能看到注册中心界面了

### 创建Eureka客户端

Eureka客户端，其实就是服务的提供方，对外提供服务的应用。

1.创建一个springboot项目，导入依赖

```java
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    // 写一个接口方便测试
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

```

2.配置

```java
spring.application.name=eureka-client
server.port=8080

# 注册中心地址
eureka.client.service-url.defaultZone=http://localhost:8180/eureka
# 启用ip配置 这样在注册中心列表中看见的是以ip+端口呈现的
eureka.instance.prefer-ip-address=true
# 实例名称  最后呈现地址：ip:8080
eureka.instance.instance-id=${spring.cloud.client.ip-address}:${server.port}

```

3.启动类加入注解@EnableEurekaClient (也可使用 @EnableDiscoveryClient)

```java
@EnableEurekaClient
@SpringBootApplication
public class MsetApplication {

    public static void main(String[] args) {
        SpringApplication.run(MsetApplication.class, args);
    }
}
```

4.写个接口

```java
RestController
public class TestController {
    @GetMapping("/")
    public String index(){
        return "sss";
    }
}
```

启动应用，再次访问：http://localhost:8180/ ，可以看见服务已经注册成功。

### Eureka自我保护模式

默认情况下，如果Eureka Server在一定时间内没有接收到某个微服务实例的心跳，Eureka Server将会注销该实例（默认90秒）。但是当网络分区故障发生时，微服务与Eureka Server之间无法正常通信，这就可能变得非常危险了，因为微服务本身是健康的，此时本不应该注销这个微服务。

Eureka Server通过“自我保护模式”来解决这个问题，当Eureka Server节点在短时间内丢失过多客户端时（可能发生了网络分区故障），那么这个节点就会进入自我保护模式。一旦进入该模式，Eureka Server就会保护服务注册表中的信息，不再删除服务注册表中的数据（也就是不会注销任何微服务）。当网络故障恢复后，该Eureka Server节点会自动退出自我保护模式。

可以通过配置：

```java
eureka.server.enable-self-preservation=false
```

关闭自我保护模式。

[springcloud官方文档](http://cloud.spring.io/spring-cloud-static/Finchley.RELEASE/single/spring-cloud.html#_appendix_compendium_of_configuration_properties)