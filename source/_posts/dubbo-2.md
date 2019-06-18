---
title: dubbo运维相关知识
date: 2019-05-27 17:36:27
tags: cloud
---

**重要**

[架构图](<http://dubbo.apache.org/zh-cn/docs/dev/design.html>)

### 启动时检查

Dubbo 缺省会在启动时检查依赖的服务是否可用，不可用时会抛出异常，阻止 Spring 初始化完成，以便上线时，能及早发现问题，默认 `check="true"`。

<!--more-->

### 配置方式

java -D 启动时配置》dubbo.xml（application.properties）》dubbo.properties

dubbo.properties

### 配置超时设置。

@reference（timeout ）dubbo.consummer

调用超时抛异常 方法级优先 接口次之，全局次之 级别一样消费方优先，提供方次之。

### 配置重试次数

@reference retries=3

### dubbo 多版本控制

么两边分别在@service @@Reference注解上定义版本号

### 本地存根

远程服务后，客户端通常只剩下接口，而实现全在服务器端，但提供方有些时候想在客户端也执行部分逻辑，比如：做 ThreadLocal 缓存，提前验证参数，调用失败后伪造容错数据等等，此时就需要在 API 中带上 Stub，客户端生成 Proxy 实例，会把 Proxy 通过构造函数传给 Stub [[1\]](http://dubbo.apache.org/zh-cn/docs/user/demos/local-stub.html#fn1)，然后把 Stub 暴露给用户，Stub 可以决定要不要去调 Proxy。

```java
package com.foo;
public class BarServiceStub implements BarService {
    private final BarService barService;
    
    // 构造函数传入真正的远程代理对象
    public BarServiceStub(BarService barService){
        this.barService = barService;
    }
 
    public String sayHello(String name) {
        // 此代码在客户端执行, 你可以在客户端做ThreadLocal本地缓存，或预先验证参数是否合法，等等
        try {
            return barService.sayHello(name);
        } catch (Exception e) {
            // 你可以容错，可以做任何AOP拦截事项
            return "容错数据";
        }
    }
}
```

