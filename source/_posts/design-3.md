---
title: 设计模式——桥接模式
date: 2019-07-17 23:02:40
tags: 设计模式
---

# 桥接模式

桥接模式(Bridge Pattern)：将抽象部分与它的实现部分分离，使它们都可以独立地变化。它是一种对象结构型模式，又称为柄体(Handle and Body)模式或接口(Interface)模式。

设想如果要绘制矩形、圆形、椭圆、正方形，我们至少需要4个形状类，但是如果绘制的图形需要具有不同的颜色，如红色、绿色、蓝色等，此时至少有如下两种设计方案：

1. 为每一种形状都提供一套各种颜色的版本。
2. 根据实际需要对形状和颜色进行组合

对于有两个变化维度（即两个变化的原因）的系统，采用第二种方案来进行设计系统中类的个数更少，且系统扩展更为方便。第二种方案即是桥接模式的应用。桥接模式将继承关系转换为关联关系，从而降低了类与类之间的耦合，减少了代码编写量。对于有两个变化维度（即两个变化的原因）的系统，采用桥接模式开发更为方便简洁。桥接模式将继承关系转换为关联关系，从而降低了类与类之间的耦合，减少了代码编写量。

<!--more-->

## 模式结构

桥接模式包含如下角色：

- Abstraction：抽象类，桥接类
- RefinedAbstraction：扩充抽象类
- Implementor：实现类，被桥接的接口
- ConcreteImplementor：具体实现类

## 源码导读

JDBC是基于Java支持多种数据库的操作，但是不同数据库的自我实现和传输协议都不尽相同，难道Java为每一种数据库写一种接口去支持数据库厂商的实现，显然违背了精简设计的原则，这里Java做的是提供一套接口让厂商自己实现，一套接口给程序开发者调用，两者的结合就是经典的桥接模式。作为程序员操作jdbc是这样的：

```java
    Class.forName("com.mysql.jdbc.Driver");
    String url = "";
    String user = "";
    String password = "";
    Connection con = DriverManager.getConnection(url, user, password);
    Statement statement = connection.createStatement();
    String sql = "insert into student (name,age) VALUE ('" + name + "'," + age + ")";
    statement.execute(sql);

```

我们来看看``部分源码

```java
 private static Connection getConnection(String var0, Properties var1, Class<?> var2) throws SQLException {
        ClassLoader var3 = var2 != null ? var2.getClassLoader() : null;
        Class var4 = DriverManager.class;
        synchronized(DriverManager.class) {
            if (var3 == null) {
                var3 = Thread.currentThread().getContextClassLoader();
            }
        }

        if (var0 == null) {
            throw new SQLException("The url cannot be null", "08001");
        } else {
            println("DriverManager.getConnection(\"" + var0 + "\")");
            SQLException var10 = null;
            Iterator var5 = registeredDrivers.iterator();

            while(true) {
                while(var5.hasNext()) {
                    DriverInfo var6 = (DriverInfo)var5.next();
                    if (isDriverAllowed(var6.driver, var3)) {
                        try {
                            println("    trying " + var6.driver.getClass().getName());
                            Connection var7 = var6.driver.connect(var0, var1);
                            if (var7 != null) {
                                println("getConnection returning " + var6.driver.getClass().getName());
                                return var7;
                            }
                        } catch (SQLException var8) {
                            if (var10 == null) {
                                var10 = var8;
                            }
                        }
                    } else {
                        println("    skipping: " + var6.getClass().getName());
                    }
                }

                if (var10 != null) {
                    println("getConnection failed: " + var10);
                    throw var10;
                }

                println("getConnection: no suitable driver found for " + var0);
                throw new SQLException("No suitable driver found for " + var0, "08001");
            }
        }
    }

```

看这几行代码

```java
 ClassLoader var3 = var2 != null ? var2.getClassLoader() : null;
        Class var4 = DriverManager.class;
        synchronized(DriverManager.class) {
            if (var3 == null) {
                var3 = Thread.currentThread().getContextClassLoader();
            }
        }
	 ......
     ......
Connection var7 = var6.driver.connect(var0, var1);
```



其实这里`DriverManager`获得`Connection`是通过反射和类加载机制从数据库驱动包的`driver`中拿到连接，所以这里真正参与桥接模式的是`driver`，而`DriverManager`和桥接模式没有关系，`DriverManager`只是对`driver`的一个管理器。而我们作为使用者只去关心`Connection`，不会去关心`driver`，因为我们的操作都是通过操作`Connection`来实现的。这样分析下来这个桥接就清晰了逻辑——`java.sql.Driver`作为抽象桥类，而驱动包如`com.mysql.jdbc.Driver`具体的实现桥接类，而`Connection`是被桥接的对象。这里的两个维度是：

- 数据库类型的不同（驱动不同）
- 数据库的连接信息不同（URL，username,password）

现在假设一个这样的场景-我们设计了一个框架，需要对外提供api,但是这个框架内部某个类需要频繁变更，很不稳定，但是我们提供的api不能一直变吧。如何将api的方法和频繁变更的代码隔离开呢，其实就可以考虑适配器模式或者桥接模式。

