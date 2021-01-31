---
title: java动态代理
date: 2019-05-13 09:58:38
tags: 设计模式
---

### 什么是代理
&emsp; &emsp;代理是一种软件设计模式，这种设计模式不直接访问被代理对象，而访问被代理对象的方法，详尽的解释可参考《java设计模式之禅》，里面的解释还是很通俗的。给个《java设计模式之禅》下载地址：https://pan.baidu.com/s/1GdFmZSx67HjKl_OhkwjqNg

&emsp; &emsp;在JDK中提供了实现动态代理模式的机制，cglib也是一个用于实现动态代理的框架，在这里我介绍jdk自带的动态代理机制是如何使用的。先上代码再慢慢解释：

<!--more-->

```java
// 定义一个接口，接口中只有一个抽象方法，这个方法便是将要被代理的方法
public interface Subject {
  String test(String string);
}

```

```java
// 定义 一个类实现这个方法，方法里写上自己的逻辑。
public class SubjectImpl implements Subject {

  @Override
  public String test(String string) {
      String test=string+string;
      return test;
  }
}
```

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
// 定义一个代理类，这个代理必须要实现invocaHandler 接口，用以指定这个类为一个代理类
public class MyProxy implements InvocationHandler {
    private Object target;
    public MyProxy( Object target){
        this.target=target;
    }
    // 实现 invoke方法，这个方法将是后面代码中实际执行的方法
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("开始执行动态代理");
        Object result=method.invoke(target,args);
        return  result;
    }
    // Proxy类为反射机制中的一个类，用于获得代理对象
    public <T> T getProxy(){
      /* newProxyInstance方法的参数解释：
      ** 被代理对象的类加载器：target.getClass().getClassLoader()
      ** 被代理的方法：target.getClass().getInterfaces()
      **代理对象：this
      */
        return (T) Proxy.newProxyInstance(target.getClass().getClassLoader(),target.getClass().getInterfaces(),this);
    }
}
```

```java
public static void main(String[] args) {
        // 创建一个被代理对象
       Subject subject=new SubjectImpl();
       // 创建一个代理对象
       Subject proxy=new MyProxy(subject).getProxy();
       // 调用代理的方法
       System.out.println(proxy.test("test"));
   }
```
输出结果：
```java
开始执行动态代理
testtest

```
&emsp; &emsp;我们知道spring 的AOP是通过动态代理实现的,现在让我们好好分析一下动态代理，示例中定义了一个接口 Subject，一个继承接口的SubjectImpl类,一个实现了InvocationHandler的MyProxy类，并调用了Proxy.newProxyInstance方法。Subject定义了将要被代理执行的方法，SubjectImpl是被代理的类（雇主），MyProxy类是代理执行的类（跑腿的），它的invoke(Object proxy, Method method, Object[] args)方法便是实际被执行的方法，它的第一个参数proxy作用：
> - 可以使用反射获取代理对象的信息（也就是proxy.getClass().getName()）
> - 可以将代理对象返回以进行连续调用，这就是proxy存在的目的，因为this并不是代理对象(MyProxy虽然是代理的类，但代理对象是 Proxy.newProxyInstance方法生成的。)。

method 是被代理的方法类型对象，args是方法的参数数组。通过Proxy.newProxyInstance生成代理类后就可以执行其中的代理方法了。


&emsp; &emsp;如果我们直接执行SubjectImpl.test()方法则只返回一个字符串，但使用动态代理我们可以在方法执行前和执行后加上自己的逻辑，这样大大提高了代码的复用性；想一想，如果你写了一堆方法，方法里很多代码是一样的，这样的代码是不是很丑？好，现在你把重复的代码单独抽出来做一个方法，但这样你的每个方法都被写死了，和那个公共的方法耦合在一起，这样很不灵活。如果我突然想一部分方法的公共方法是a(),一部分方法的公共方法是b(),那改起来很麻烦，扩展性很差。使用动态代理就很好的解决了这个问题，被代理对象可以任意指定，代理的逻辑可以任意实现，二者互相独立互不影响，并且可以由客户端任意进行组合，这就是所谓的动态。