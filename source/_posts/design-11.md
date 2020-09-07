---
title: 设计模式-策略模式
date: 2020-02-02 17:37:07
tags: 设计模式
---

策略（Strategy）模式的定义：该模式定义了一系列算法，并将每个算法封装起来，使它们可以相互替换，且算法的变化不会影响使用算法的客户。策略模式属于对象行为模式，它通过对算法进行封装，把使用算法的责任和算法的实现分割开来，并委派给不同的对象对这些算法进行管理。策略模式有以下优点：

- 多重条件语句不易维护，而使用策略模式可以避免使用多重条件语句。
- 策略模式提供了一系列的可供重用的算法族，恰当使用继承可以把算法族的公共代码转移到父类里面，从而避免重复的代码。
- 策略模式可以提供相同行为的不同实现，客户可以根据不同时间或空间要求选择不同的。
- 策略模式提供了对开闭原则的完美支持，可以在不修改原代码的情况下，灵活增加新算法。
- 策略模式把算法的使用放到环境类中，而算法的实现移到具体策略类中，实现了二者的分离。

<!--more-->

# 模式结构

策略模式是准备一组算法，并将这组算法封装到一系列的策略类里面，作为一个抽象策略类的子类。策略模式的重心不是如何实现算法，而是如何组织这些算法，从而让程序结构更加灵活，具有更好的维护性和扩展性，现在我们来分析其基本结构和实现方法。
策略模式的主要角色如下：

- 抽象策略（Strategy）类：定义了一个公共接口，各种不同的算法以不同的方式实现这个接口，环境角色使用这个接口调用不同的算法，一般使用接口或抽象类实现。
- 具体策略（Concrete Strategy）类：实现了抽象策略定义的接口，提供具体的算法实现。
- 环境（Context）类：持有一个策略类的引用，最终给客户端调用。

# 源码导读

策略模式的结构很简单，而spring的bean注入特性让我们在spring 框架中使用策略模式很方便，在spring中，对于同一类bean不同的别名是可以注入到一个map中或者list中的，下面的代码演示了如何在spring中方便的使用策略模式
先定义一个抽象父类：

```
public interface Message {

    /**
     * 抽象策略
     */
    String test(String test);

}
```

再定义不同的实现类

```
@Service("testA")
public class TestA{
    @Override
    String test(String test) {
        return "testA:"+test;
    }
}

@Service("testB")
public class TestA{
    @Override
    String test(String test) {
        return "testB:"+test;
    }
}

@Service("testC")
public class TestA{
    @Override
    String test(String test) {
        return "testC:"+test;
    }
}
```

然后在环境类中使用这些策略

```
@Service
public class Subject{
    @Autowired
    Map<String,Message> messageStrategy

    public void check(){
       Message message= messageStrategy.get("testB")
       System.out.print(message.test())
    }
}
```

以上就是一个简单的策略模式，在spring中使用该模式可以减少条件分支的代码量，而且它的扩展性也很好。