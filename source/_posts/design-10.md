---
title: 设计模式-代理模式（proxy）
date: 2020-02-02 17:35:26
tags: 设计模式
---

代理模式的定义：由于某些原因需要给某对象提供一个代理以控制对该对象的访问。这时，访问对象不适合或者不能直接引用目标对象，代理对象作为访问对象和目标对象之间的中介。

代理模式的主要优点有：
代理模式在客户端与目标对象之间起到一个中介作用和保护目标对象的作用；
代理对象可以扩展目标对象的功能；
代理模式能将客户端与目标对象分离，在一定程度上降低了系统的耦合度；

其主要缺点是：
在客户端和目标对象之间增加一个代理对象，会造成请求处理速度变慢；
增加了系统的复杂度；

<!--more-->

## 模式结构

代理模式的主要角色如下。
抽象主题（Subject）类：通过接口或抽象类声明真实主题和代理对象实现的业务方法。
真实主题（Real Subject）类：实现了抽象主题中的具体业务，是代理对象所代表的真实对象，是最终要引用的对象。
代理（Proxy）类：提供了与真实主题相同的接口，其内部含有对真实主题的引用，它可以访问、控制或扩展真实主题的功能。

## 源码导读

在代理模式中动态代理是在各个框架中使用最广泛的一种设计模式，dubbo中 feign中 mybaits中，都有使用到动态代理。在dubbo中，在接口上添加@refrence ，dubbo就会根据这个接口生成一个代理实例来供消费者用生产者。在feign中也是一样；mybatis中你只要指定包扫描的路径，就会在spring中注入一个mapper，实际上这个mapper就是根据接口和xml生成的代理对象。实际上，这种“申明式的”功能实现方式，都是通过代理模式来实现的。

下面我们通过cglib来写一个“残疾缩水”版的mybatis：

首先要整一个xml，我这里用properties代替

test.properties:

```
testA=select * from user where id=
testB=select * from user where username=
```

再整一个接口：

```
  interface Test {

    String testA(int id);
    String testB(String username);
}
```

再是代码增强处理器，这里面完成对接口的代理逻辑

```
class MyInvokationHandler implements MethodInterceptor {

    private static Map<String,String> sqlMap;

    {
        HashMap<String, String> map = new HashMap<>();



        Properties prop = new Properties();
        InputStream in = SystemMenuController.class.getClassLoader().getResourceAsStream("test.properties");
        try {
            prop.load(in);
            Iterator<String> it = prop.stringPropertyNames().iterator();
            while (it.hasNext()) {
                String key = it.next();
                map.put(key,prop.getProperty(key));
            }
            in.close();
        } catch (java.io.IOException e) {
            e.printStackTrace();
        }
        sqlMap=map;
    }


    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        String name = method.getName();
        String s = sqlMap.get(name);
        return s+objects[0];
    }
}
```

包扫描和启动时注入容器略，数据源也略,用个main方法模拟一下：

```
public static void main(String[] args) {

      Enhancer enhancer = new Enhancer();
      enhancer.setSuperclass(Test.class);
      enhancer.setCallback(new MyInvokationHandler());
      Test test = (Test) enhancer.create();
      System.out.println(test.testA(1));
       System.out.println(test.testB("hhh"));
  }
```

最终在控制台中打印：

```
select * from user where id=1
select * from user where id=hhh
```

代理模式是一个很强大实用性很强的模式，动态代理大大减少了我们的开发任务，同时减少了对业务接口的依赖，降低了耦合度。代理模式的使用场景可以总结为：

- 远程代理，这种方式通常是为了隐藏目标对象存在于不同地址空间的事实，方便客户端访问。例如，用户申请某些网盘空间时，会在用户的文件系统中建立一个虚拟的硬盘，用户访问虚拟硬盘时实际访问的是网盘空间。
- 虚拟代理，这种方式通常用于要创建的目标对象开销很大时。例如，下载一幅很大的图像需要很长时间，因某种计算比较复杂而短时间无法完成，这时可以先用小比例的虚拟代理替换真实的对象，消除用户对服务器慢的感觉。
- 安全代理，这种方式通常用于控制不同种类客户对真实对象的访问权限。
- 智能指引，主要用于调用目标对象时，代理附加一些额外的处理功能。例如，增加计算真实对象的引用次数的功能，这样当该对象没有被引用时，就可以自动释放它。
- 延迟加载，指为了提高系统的性能，延迟对目标的加载。例如，Hibernate 中就存在属性的延迟加载和关联表的延时加载。