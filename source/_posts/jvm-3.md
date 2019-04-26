---
title: jvm基础篇三之垃圾收集器
date: 2019-04-24 10:49:15
tags: jvm
---


##  垃圾收集器介绍
&emsp; &emsp;java内存在运行时被分为多个区域，其中程序计数器、虚拟机栈、本地方法栈三个区域随线程生成和销毁；每一个栈帧中分配多少内存基本上是在类结构确定下来时就已知的，在这几个区域内就不需要过多考虑回收问题，因为方法结束或者线程结束时，内存自然就跟着回收了。而堆区就不一样了，我们只有在程序运行的时候才能知道哪些对象会被创建，这部分内存是动态分配的，垃圾收集器主要关注的也就是这部分内存。

<!--more-->

##  垃圾收集器算法
&emsp; &emsp;jdk11刚发布不久，这个版本发布了一款新的垃圾收集器——G1垃圾收集器,这款垃圾收集器有很多优异的特性，我会在后文做介绍，这里先从简单的慢慢说起。

&emsp; &emsp;引用计数算法是最初垃圾收集器采用的算法，也是相对简单的一种算法，其原理是：给对象中添加一个引用计数器，每当有一个地方引用它的时候这个计数器就加一；当引用失效，计数器就减一；任何时刻计数器为0则该对象就会被垃圾收集器回收。这种算法的缺点是当对象之间相互循环引用的时候，对象将永远不会被回收。举个例子——有类TestOne,类TestTwo;它们互相是对方的成员，如下：
```java
 public static void main(String[] args) {
    TestOne testOne=new TestOne();
    TestTwo testTwo=new TestTwo();
    testOne.obj=testTwo;
    testTwo.obj=testOne;
    testOne=null;
    testTwo=null;
}

```
理论上当代码执行到testTwo=null的时候 new TestOne() new TestTwo() 两块内存应该要被回收的，但是因为它们相互引用对方导致引用计数器不为0，所以这两块内存没有引用指向它们却无法被回收——这便是这种算法所存在的问题。

&emsp; &emsp;可达性分析算法是使用比较广泛的算法。这个算法的基本思路是通过一系列的称为“GC Roots”的对象作为起点，从这些节点向下搜索，搜索所走过的路径称作引用链；当一个对象和GC Roots之间不存在引用链的时候，这个对象将被回收；也就是说一个存活的对象向上追溯它的引用链，其头部必然是GC Roots,如果不是将被回收。在虚拟机中可以作为GC Roots的可以是：虚拟机栈中引用的对象、方法区中类静态属性引用的对象、方法区中常量引用的对象，本地方法栈中Native方法引用的对象；在堆区一个存活的对象被这些对象所直接引用或间接引用(引用又分为强引用、软引用、弱引用、、虚引用，引用强调依次降低，感兴趣的可以详细了解一下)。
&emsp; &emsp;当一个对象的引用链中没有GC Roots的时候并不会被马上回收，第一次他会被标记并筛选，当对象没有覆盖finalize()方法或该方法已经被虚拟机调用过，那么它会被放入一个叫做F-Queue的队列中等待被虚拟机自动回收；否则虚拟机会执行finalize()方法——当我们没有重写finalize()方法时，对象内存自然被回收掉，如果重写了这个方法，那么结果就会变得很有趣，下面做一个示例：
```java
public class Main {
    public static  Main test=null;

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        System.out.println("执行了一次 finalize()");
        Main.test=this;
    }

    public static void main(String[] args) {
        test=new Main();
        // 让test失去 GC RootS
        test=null;
        // 调用 finalize()方法
        System.gc();
        // sleep一会确保finalize()方法执行
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        // 因为在finalize()方法中重新将this(也就是 new Main())赋值给了test 所以没被回收
        if(test!=null){
            System.out.println("对象存活了下来");
        }else{
            System.out.println("对象死了");
        }
        // 再来一次
        test=null;
        System.gc();
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        // 这一次却死了，因为finalize()方法已经被执行过，虚拟机直接将对象扔到 F-Queue里面等待回收
        if(test!=null){
            System.out.println("对象存活了下来");
        }else{
            System.out.println("对象死了");
        }
    }

}
```
运行结果：
> 执行了一次 finalize()<br/>
> 对象存活了下来<br/>
> 对象死了

##  回收方法区
&emsp; &emsp;因为方法区的内存回收条件很苛刻，因此方法区被人称作永久代，在这个区域回收的内存主要为废弃的常量和无用的类；那么如何判定一个常量是否废弃呢？比如当一个字符串进入了常量池，但没有任何地方引用它，如果此时发生了内存回收，那么这个常量就会被清除出常量池——发生场景：一个类有一个成员 pubulic static String test="aaa";当这个类被加载的时候"aaa"进入常量池，当其他地方没有字符串等于"aaa"的时候并且此时这个类由于某种原因被卸载掉，此时这个"aaa"将会被回收。如何判定一个类是无用的类呢？需要满足三个条件：
   > 该类所有的实例都被回收<br/>
   >    加载该类的ClassLoader已经被回收
   >    <br/>该类的Class对象没在任何地方被引用，无法通过反射访问该类

## 写在末尾
   &emsp; &emsp;本来还想写垃圾回收的算法的，结果时间不太够，那就留在下一次写吧。微信留言功能不能开通，有没有大佬指点一下是怎么回事？开通留言和大佬们沟通一波岂不是美滋滋。