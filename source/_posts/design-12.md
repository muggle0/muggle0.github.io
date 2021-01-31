---
title: 设计模式-命令模式
date: 2020-02-02 17:37:56
tags: 设计模式
---

当我们的代码中”方法的请求者” 和 “方法的实现者” 之间存在较为紧密的耦合的时候，这段代码的后续维护会变得很困难。如果我们想对方法进行回滚 撤销等操作的话就会很困难；使用命名模式可解决这一问题。

在现实生活中，这样的例子也很多，例如，电视机遥控器（命令发送者）通过按钮（具体命令）来遥控电视机（命令接收者），还有计算机键盘上的“功能键”等。

<!--more-->



命令（Command）模式的定义如下：将一个请求封装为一个对象，使发出请求的责任和执行请求的责任分割开。这样两者之间通过命令对象进行沟通，这样方便将命令对象进行储存、传递、调用、增加与管理。
命令模式的优点：

- 降低系统的耦合度。命令模式能将调用操作的对象与实现该操作的对象解耦。
- 增加或删除命令非常方便。采用命令模式增加与删除命令不会影响其他类，它满足“开闭原则”，对扩展比较灵活。
- 可以实现宏命令。命令模式可以与组合模式结合，将多个命令装配成一个组合命令，即宏命令。
- 方便实现 Undo 和 Redo 操作。命令模式可以与后面介绍的备忘录模式结合，实现命令的撤销与恢复。

# 模式结构

命令模式包含以下主要角色：

- 抽象命令类（Command）角色：声明执行命令的接口，拥有执行命令的抽象方法 execute()。
- 具体命令角色（Concrete Command）角色：是抽象命令类的具体实现类，它拥有接收者对象，并通过调用接收者的功能来完成命令要执行的操作。
- 实现者/接收者（Receiver）角色：执行命令功能的相关操作，是具体命令对象业务的真正实现者。
- 调用者/请求者（Invoker）角色：是请求的发送者，它通常拥有很多的命令对象，并通过访问命令对象来执行相关请求，它不直接访问接收者。

# 源码导读

在springboot的redis客户端的`redisTemplate`类中就有使用到命令模式。
在命令模式中，有三个重要的角色，我们只要找到这三个重要的角色就能捋清命令模式的的脉络了，这三个角色是“客户端”，“命令”，“服务端”。
在`RedisTemplate` 中存在一个`execute` 方法，这个就是服务端执行命令的方法，而它的方法参数`RedisCallback` 就是命令类了，我们看看如何在客户端构造一个命令给`RedisTemplate`去执行。

```
public boolean lockByLua(String key, String value, Long expiredTime){
        String strExprie = String.valueOf(expiredTime);
        StringBuilder sb = new StringBuilder();
        sb.append("if redis.call(\"setnx\",KEYS[1],ARGV[1])==1 ");
        sb.append("then ");
        sb.append("    redis.call(\"pexpire\",KEYS[1],KEYS[2]) ");
        sb.append("    return 1 ");
        sb.append("else ");
        sb.append("    return 0 ");
        sb.append("end ");
        String script = sb.toString();
        RedisCallback<Boolean> callback = (connection) -> {
            return connection.eval(script.getBytes(), ReturnType.BOOLEAN, 2, key.getBytes(Charset.forName("UTF-8")),strExprie.getBytes(Charset.forName("UTF-8")), value.getBytes(Charset.forName("UTF-8")));
        };
        Boolean execute = stringRedisTemplate.execute(callback);
        return execute;
    }
```

以上代码是通过`stringRedisTemplate`执行一个lua脚本，`lockByLua`就是客户端的方法。对于命令模式而言，命令执行方法都是按照`executeXXX`这样的格式命名。