---
title: 多线程编程基础第一篇
date: 2019-04-22 16:20:55
tags: thread
---

作者：muggle
## java并发相关概念

### 同步和异步
同步和异步通常来形容一次方法的调用。同步方法一旦开始，调用者必须等到方法结束才能执行后续动作；异步方法则是在调用该方法后不必等到该方法执行完就能执行后面的代码，该方法会在另一个线程异步执行，异步方法总是伴随着回调，通过回调来获得异步方法的执行结果；

### 并发和并行
很多人都将并发与并行混淆在一起，它们虽然都可以表示两个或者多个任务一起执行，但执行过程上是有区别的。并发是多个任务交替执行，多任务之间还是串行的；而并行是多个任务同时执行，和并发有本质区别。
对计算机而言，如果系统内只有一个cpu，而使用多进程或者多线程执行任务，那么这种情况下多线程或者多进程就是并行执行，并行只可能出现在多核系统中。当然，对java程序而言，我们不必去关心程序是并行还是并发。

<!--more-->

### 临界区

临界区表示的是多个线程共享但同时只能有一个线程使用它的资源。在并行程序中临界区资源是受保护的，必须确保同一时刻只有一个线程能使用它。

### 阻塞

如果一个线程占有了临界区的资源，其他需要使用这个临界区资源的线程必须在这个临界区进行等待——线程被挂起，这种情况就是发生了阻塞——线程停滞不前。

### 死锁\饥饿\活锁

死锁就是多个线程需要其他线程的资源才能释放它所拥有的资源，而其他线程释放这个线程需要的资源必须先获得这个线程所拥有的资源，这样造成了矛盾无法解开；如图1情形就是发生死锁现象：

![](http://a2.qpic.cn/psb?/V13ysUCU2bV4he/zBrKU1zKzRRphjYm8*58YnBjOH0x7EvRxnWkrr.0oeE!/b/dMEAAAAAAAAA&ek=1&kp=1&pt=0&bo=2QENAQAAAAARF*Q!&tl=3&vuin=1793769323&tm=1555678800&sce=60-2-2&rf=viewer_4)

<center>图1：生活中的死锁现象</center>

活锁就是两个线程互相谦让资源，结果就是谁也拿不到资源导致活锁；就好比过马路，行人给车让道，车又给行人让道，结果就是车和行人都停在那不走。

饥饿就是，某个线程优先级特别低老是拿不到资源，导致这个线程一直无法执行

### 并发级别

并发级别分为阻塞，无饥饿，无障碍，无锁，无等待几个级别；根据名字我们也能大概猜出这几个级别对应的什么情形；阻塞，无饥饿和无锁都好理解；我们说一下无障碍和无等待；

无障碍：无障碍级别默认各个线程不会发生冲突，不会互相抢占资源，一旦抢占资源就认为线程发生错误，进行回滚。

无等待：无等待是在无锁上的进一步优化，限制每个线程完成任务的步数；

### 并行的两个定理

加速比：加速比=优化前系统耗时/优化后系统耗时

Amdahl定理： 加速比=1/[F+(1-F)/n] 其中 n表示处理器个数 ，F是程序中只能串行执行的比例——串行率；由公式可知，想要以最小投入，得到最高加速比即 F+(1-F)/n取到最小值，F和n都对结果有很大影响，在深入研究就是数学问题了；

Gustafson定律： 加速比=n-F(n-1)，这两定律区别不大，都体现了单纯的减少串行率，或者单纯的加CPU都无法得到最优解。

## Java中的并行基础

### volatile关键字和程序的原子性，可见性，有序性

原子性指的是一个操作是不可中断的，要么成功要么失败，不会被其他线程所干扰；比如 int=1,这一操作在cpu中分为好几个指令，但对程序而言这几个指令是一体的，只有可能执行成功或者失败，不可能发生只执行了一半的操作；对不同CPU而言保证原子性的的实现方式各有不同，就英特尔CPU而言是使用一个lock指令来保证的。

可见性指某一线程改变某一共享变量，其他线程未必会马上知道。

有序性指对一个操作而言指令是按一定顺序执行的，但编译器为了提高程序执行的速度，会重排程序指令；cpu在执行指令的时候采用的是流水线的形式，上一个指令和下一个指令差一个工步。比如A指令分三个工步：1. 操作内存a，2.操作内存b，3.操作内存c；现假设有个指令B操作流程和A一样，那么先执行指令A在执行指令B时间全利用上了，中间没有停顿等待；但如果有三个这样的指令在流水线上执行：a>b>c，b>e>c，c>e>a；这样的指令顺序就会发生等待降低了CPU的效率，编译器为了避免这种事情发生，会适当优化指令的顺序进行重排。

volatile关键字在java中的作用是保证变量的可见性和防止指令重排。

### 线程的相关操作

*创建线程有三种方法*

- 继承Thread类创建线程
- 实现Runnable接口创建线程
- 使用Callable和Future创建线程

*终止线程的方法*

终止线程可调用stop()方法，但这个方法是被废弃不建议使用的，因为强制终止一个线程会引起数据的不一致问题。比如一个线程数据写到一半被终止了，释放了锁，其他线程拿到锁继续写数据，结果导致数据发生了错误。终止线程比较好的方法是“让程序自己终止”，比如定义一个标识符，当标识符为true的时候直让程序走到终点，这样就能达到“自己终止”的目的。

*线程的中断等待和通知*

interrupt()方法可以中断当前程序，object.wait() 方法让线程进入等待队列，object.notify()随机唤醒等待队列的一个线程， object.notifyAll()唤醒等待队列的所有线程。object.wait()必须在synchronzied语句中调用；执行wait，notify方法必须获得对象的监视器，执行结束后释放监视器供其他线程获取。

*join*

join()方法功能是等待其他线程“加入”，可以理解为将某个线程并为自己的子线程，等子线程走完或者等子线程走规定的时间，主线程才往下走；join的本质是调用调用线程对象的wait方法，当我们执行wait或者notify方法不应该获取线程对象的的监听器，因为可能会影响到其他线程的join。

*yield*

yield是线程的“谦让”机制，可以理解为当线程抢到cpu资源时，放弃这次资源重新抢占，yield()是Thread里的一个静态方法。

### 线程组

如果一个多线程系统线程数量众多而且分工明确，那么可以使用线程组来分类。

```java
	
    @Test
    public void contextLoads() {
        ThreadGroup testGroup=new ThreadGroup("testGroup");
        Thread a = new Thread(testGroup, new MyRunnable(), "a");
        Thread b = new Thread(testGroup, new MyRunnable(), "b");
        a.start();
        b.start();
        int i = testGroup.activeCount();
    }

    public static class MyRunnable implements Runnable{
        @Override
        public void run() {
            System.out.println("test");
        }
    }
```

图示代码创建了一个"testGroup"线程组。

### 守护线程

守护线程是一种特殊线程，它类似java中的异常系统，主要是概念上的分类，与之对应的是用户线程。它功能应该是在后台完成一些系统性的服务；设置一个线程为守护线程应该在线程start之前setDaemon()。

### 线程优先级

java中线程可以有自己的优先级，优先级高的更有优势抢占资源；线程优先级高的不一定能抢占到资源，只是一个概率问题，而对应优先级低的线程可能会发生饥饿；

在java中使用1到10表示线程的优先级，使用setPriority()方法来进行设置，数字越大代表优先级越高；

