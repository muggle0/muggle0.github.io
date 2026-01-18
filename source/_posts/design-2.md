---
title: 设计模式——三个工厂模式
date: 2019-07-17 22:55:21
tags: 设计模式
---

## 简单工厂模式

简单工厂模式(Simple Factory Pattern)：又称为静态工厂方法(Static Factory Method)模式，它属于类创建型模式。在简单工厂模式中，可以根据参数的不同返回不同类的实例。简单工厂模式专门定义一个类来负责创建其他类的实例，被创建的实例通常都具有共同的父类。



### 模式结构

简单工厂模式包含如下角色：

- Factory：工厂角色，工厂角色负责实现创建所有实例的内部逻辑
- Product：抽象产品角色，抽象产品角色是所创建的所有对象的父类，负责描述所有实例所共有的公共接口
- ConcreteProduct：具体产品角色，具体产品角色是创建目标，所有创建的对象都充当这个角色的某个具体类的实例。


<!-- more -->


### 源码导读

```java
 public static void main(String[] args) {
        // 资源加载
        ClassPathResource classPathResource = new ClassPathResource("spring-bean.xml");
        // XmlBeanFactory 加载资源并解析注册bean
        BeanFactory beanFactory = new XmlBeanFactory(classPathResource);
        // BeanFactory.getBean();
        UserBean userBean = (UserBean) beanFactory.getBean("userBean");
        System.out.println(userBean.getName());
}
```

这个`XmlBeanFactory`便可以看做是一个稍微变形的简单工厂，`getBean()`方法便是获取产品的实例方法，`userBean`便是我们的产品。如果我们以后遇到与spring中`XmlBeanFactory`类似场景我们便可依瓢画葫芦写出一个漂亮的简单工厂。

## 工厂方法模式

也叫虚拟构造器(Virtual Constructor)模式或者多态工厂(Polymorphic Factory)模式，它属于类创建型模式。在工厂方法模式中，工厂父类负责定义创建产品对象的公共接口，而工厂子类则负责生成具体的产品对象，这样做的目的是将产品类的实例化操作延迟到工厂子类中完成，即通过工厂子类来确定究竟应该实例化哪一个具体产品类。

### 模式结构

工厂方法模式包含如下角色：

- Product：抽象产品
- ConcreteProduct：具体产品
- Factory：抽象工厂
- ConcreteFactory：具体工厂

### 源码导读

java.util.Collection接口中定义了一个抽象的iterator()方法，该方法就是一个工厂方法。
我们来看看`ArrayList`中的`iterator()`实现

```java
@NotNull public Iterator<E> iterator() {
    return new ArrayList.Itr();
}
```

它new了一个`ArrayList`的内部类`Itr` 然后将其返回，Itr：

```java
private class Itr implements Iterator<E> {
        int cursor;
        int lastRet = -1;
        int expectedModCount;

        Itr() {
            this.expectedModCount = ArrayList.this.modCount;
        }
   ......
   ......
}
```

这里`ArrayList`对`Iterator`来说就是一个工厂类，它的`iterator()`方法便是生产`Iterator`的工厂方法。

## 抽象工厂

抽象工厂模式(Abstract Factory Pattern)：提供一个创建一系列相关或相互依赖对象的接口，而无须指定它们具体的类。抽象工厂模式又称为Kit模式，属于对象创建型模式。

### 模式结构

抽象工厂模式包含如下角色：

- AbstractFactory：抽象工厂
- ConcreteFactory：具体工厂
- AbstractProduct：抽象产品
- Product：具体产品

### 源码导读

我们可以看到 抽象工厂和工厂方法的区别是——抽象多了生产相关联产品的其他方法。可以理解为对工厂方法的一个升级，我们来看`HashMap`这个类：

```java
     HashMap<Object, Object> objectHashMap = new HashMap<>();
     Set<Map.Entry<Object, Object>> entries = 		     objectHashMap.entrySet();
     Collection<Object> values = objectHashMap.values();
```

这里`HashMap` 就是抽象工厂，它的`values()`和`entrySet()`就是两个工厂方法，` Collection<Object>`和`Set<Map.Entry<Object, Object>>`是产品。注意：**抽象工厂中抽象的含义是对产品的抽象，不再是某个产品，而是某系列产品**，工厂模式类命名一般以`factory`结尾。



