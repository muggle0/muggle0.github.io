---
title: jvm系列之对象引用分析
date: 2019-05-09 12:02:50
tags: jvm
---

# java 引用介绍

在JDK 1.2以前的版本中，若一个对象不被任何变量引用，那么程序就无法再使用这个对象。对象引用被划分成简单的两种状态：可用和不可用。从JDK 1.2版本以后，对象的引用被划分为`4`种级别，从而使程序能更加灵活地控制对象的生命周期，引用的强度由高到低为：强、软、弱、虚引用。

对象生命周期：在JVM运行空间中，对象的整个生命周期大致可以分为7个阶段：创建阶段（Creation）、应用阶段（Using）、不可视阶段（Invisible）、不可到达阶段（Unreachable）、可收集阶段（Collected）、终结阶段（Finalized）与释放阶段（Free）。上面的这7个阶段，构成了 JVM中对象的完整的生命周期。

<!--more-->

## 强引用(StrongReference)

强引用是使用最普遍的引用。如果一个对象具有强引用，那垃圾回收器绝不会回收它，我们使用new关键字就是创建了一个强引用。被强引用引用的内存是无法被GC回收的，想要回收这一块的内存得等这个引用从栈内存中出来，对应的内存无引用了才能被回收。

## 软引用(SoftReference)

如果一个对象只具有软引用，则内存空间充足时，GC不会回收这块内存；单如果内存不足的时候它就会被回收，只要垃圾回收器没有回收它，该对象就可以被程序使用。软引用可用来实现内存敏感的高速缓存。

创建一个软引用的办法

```java
    String str = new String("xxx");
    SoftReference<String> softReference = new SoftReference<String>(str);
```

`softReference`就是一个软引用。

当内存不足时，`JVM`首先将软引用中的对象引用置为`null`，然后通知垃圾回收器进行回收。也就是说当软引用指向null的时候，对应的内存可能还是未被GC回收的。虚拟机会尽可能的优先回收长时间闲置不用的软引用对象。

## 弱引用(WeakReference)

弱引用比软引用有更短暂的生命周期。在GC扫描内存区域的时候，一旦发现弱引用就会马上回收它。

创建一个弱引用的方法：

```java
String str = new String("xxx");
WeakReference<String> weakReference = new WeakReference<>(str);
// 弱引用转强引用
String strongReference = weakReference.get();
```

如果一个对象是偶尔(很少)的使用，并且希望在使用时随时就能获取到，但又不想影响此对象的垃圾收集，那么你应该用Weak Reference来记住此对象。如上面代码所示，弱引用也也可以转换成强引用

## 虚引用(PhantomReference)

虚引用可以理解为形同虚设的引用，不管你这个引用指向的内存有没有在用，它都随时可能被回收掉。虚引用必须和引用队列(ReferenceQueue)联合使用。当垃圾回收器准备回收一个对象时，如果发现它还有虚引用，就会在回收对象的内存之前，把这个虚引用加入到与之关联的引用队列中。

创建虚引用的办法：

```java
 String str = new String("xxx");
ReferenceQueue queue = new ReferenceQueue();
// 创建虚引用，要求必须与一个引用队列关联
PhantomReference pr = new PhantomReference(str, queue);
```

虚引用基本上好像没啥卵用。

# 总结

GC线程在虚拟机中的优先级别很低的，因此占用cpu资源的机会很少，所以当一个内存变成非强引用的时候，不一定马上会被回收，而是看这个时候GC线程有没有在执行。如果GC在执行，它会先检查这个内存有没有有引用指向它，如果没有就回收，如果有那么根据引用的级别来采用垃圾回收策略。

