---
title: 设计模式-装饰器模式（Decorator）
date: 2020-02-02 17:33:29
tags: 设计模式
---

装饰器（Decorator）模式指在不改变现有对象结构的情况下，动态地给该对象增加一些职责（即增加其额外功能）的模式，它属于对象结构型模式。采用装饰模式扩展对象的功能比采用继承方式更加灵活；可以设计出多个不同的具体装饰类，创造出多个不同行为的组合。但是装饰模式增加了许多子类，如果过度使用会使程序变得很复杂。

<!--more-->

## 模式结构

装饰器模式的角色如下：

- 顶层接口
- 被装饰者
- 装饰器抽象类
- 装饰器

## 源码导读

装饰器模式使用的典型就是io流了，前面适配器模式我们说到过io流使用了适配器模式，用于字节流转换到字符流；装饰器模式在io流中也是一个很经典的使用。其使用的地方就是给流装饰上缓存。以输入流为例， `BufferedInputStream`就是对 `FileInputStream`的装饰，我们看一下这段代码：

```
String file = "out.txt";        InputStream ins = new FileInputStream(file);     BufferedInputStream bufin= new BufferedInputStream(ins);     int b;     while((b=bufin.read())!=-1){         System.out.println(Integer.toHexString(b));    }
```

`BufferedInputStream` 源码：

```
public class BufferedInputStream extends FilterInputStream {     public BufferedInputStream(InputStream in) {        this(in, DEFAULT_BUFFER_SIZE);    }    ......    public synchronized int read(byte b[], int off, int len) throws IOException{        ......    }}
```

它继承了 `FilterInputStream`，而 `FilterInputStream` 继承了 `InputStream`， `FileInputStream`也继承了 `InputStream` 。所以这里的角色关系为 `InputStream` 是顶层类（接口）， `FileInputStream` 是被装饰类， `BufferedInputStream` 是装饰类。`BufferedInputStream` 对 `FileInputStream`从 `InputStream`继承过来的方法进行了装饰，这里的。`FilterInputStream`占据的角色是装饰器抽象类，但其并不是个抽象类；这并不影响我们对其模式的理解。