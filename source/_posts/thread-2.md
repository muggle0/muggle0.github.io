---
title: 多线程编程基础第二篇
date: 2019-04-23 09:22:05
tags: thread
---

作者：muggle

## 扩展

cas(比较替换)：无锁策略的一种实现方式，过程为获取到变量旧值（每个线程都有一份变量值的副本），和变量目前的新值做比较，如果一样证明变量没被其他线程修改过，这个线程就可以更新这个变量，否则不能更新；通俗的说就是通过不加锁的方式来修改共享资源并同时保证安全性。

使用cas的话对于属性变量不能再用传统的int ,long等；要使用原子类代替原先的数据类型操作，比如AtomicBoolean，AtomicInteger，AtomicInteger等。

## java线程锁的分类与实现

以下分类是从多个同角度来划分，而不是以某一标准来划分，请注意

- 阻塞锁：当一个线程获得锁，其他线程就会被阻塞挂起，直到抢占到锁才继续执行，这样会导致CPU切换上下文，切换上下文对CPU而言是很耗费时间的
- 非阻塞锁：当一个线程获得锁，其他线程直接跳过锁资源相关的代码继续执行，就是非阻塞锁
- 自旋锁：当一个线程获得锁，其他线程则在不停进行空循环，直到抢到锁，这样做的好处是避免了上下文切换
- 可重入锁：也叫做递归锁，当一个线程外层函数获得锁之后 ，内层递归函数仍然可以该锁的相关代码，不受影响。
- 互斥锁：互斥锁保证了某一时刻只能有一个线程占有该资源。
- 读写锁：将代码功能分为读和写，读不互斥，写互斥；
- 公平锁/非公平锁：公平锁就是在等待队列里排最前面的的先获得锁，非公平锁就是谁抢到谁用；
- 重量级锁/轻量级锁/偏向锁：使用操作系统“Mutex Lock”功能来实现锁机制的叫重量级锁，因为这种锁成本高；轻量级锁是对重量级锁的优化，提高性能；偏向锁是对轻量级锁的优化，在无多线程竞争的情况下尽量减少不必要的轻量级锁执行路径。

<!--more-->

###  synchronized

属于阻塞锁，互斥锁，非公平锁，可重入锁，在JDK1.6以前属于重量级锁，后来做了优化；

用法：
- 指定加锁对象；
- 用于静态代码块/方法
- 用于动态代码块/方法

示例

```
		public static synchronized void test1(){
            System.out.println("test");
        }

        public  synchronized void test2(){
            System.out.println("test");
        }
                 
        public void test3(){
            synchronized (this){
                System.out.println("test");
            }
        }
```

当锁加在静态代码块/方法上时，锁作用于整个类，凡是属于这个类的对象的相关都会被上锁，当用于动态代码块/方法/对象时锁作用于对象；除此之外，synchronized可以保证线程的可见性和有序性。

### Lock

lock 是一个接口，其下有多个实现类；

方法说明：

- lock()方法是平常使用得最多的一个方法，就是用来获取锁。如果锁已被其他线程获取，则进行等待。
- tryLock()方法是有返回值的，它表示用来尝试获取锁，如果获取成功，则返回true，如果获取失败（即锁已被其他线程获取），则返回false，这个方法还可以设置一个获取锁的等待时长，如果时间内获取不到直接返回。
- 两个线程同时通过lock.lockInterruptibly()想获取某个锁时，假若此时线程A获取到了锁，而线程B只有在等待，那么对线程B调用threadB.interrupt()方法能够中断线程B的等待过程
- unLock()方法是用来释放锁
- newCondition()：生成一个和线程绑定的Condition实例，利用该实例我们可以让线程在合适的时候等待，在特定的时候继续执行；相当于得到这个线程的wait和notify方法；

### ReentrantLock

ReentrantLock重入锁，是实现Lock接口的一个类，它对公平锁和非公平锁都支持；在构造方法中传入一个boolean值，true时为公平锁，false时为非公平锁

### Semaphore(信号量)

信号量是对锁的扩展，锁每次只允许一个线程访问一个资源，而信号量却可以指定多个线程访问某个资源；信号量的构造函数为

```java
public Semaphore(int permits) {
        sync = new NonfairSync(permits);
    }
public Semaphore(int permits, boolean fair) {
        sync = fair ? new FairSync(permits) : new NonfairSync(permits);
    }
```

第一个方法指定了可使用的线程数，第二个方法的布尔值表示是否为公平锁；

acquire()方法尝试获得一个许可，如果获取不到则等待；tryAcquire()方法尝试获取一个许可，成功返回true，失败返回false，不会阻塞，tryAcquire(int i) 指定等待时间；release()方法释放一个许可。

### ReadWriteLock

读写分离锁， 读写分离锁可以有效的减少锁竞争，读锁是共享锁，可以被多个线程同时获取，写锁是互斥只能被一个线程占有，ReadWriteLock是一个接口，其中readLock()获得读锁，writeLock()获得写锁 其实现类ReentrantReadWriteLock是一个可重入得的读写锁，它支持锁的降级(在获得写锁的情况下可以再持有读锁)，不支持锁的升级（在获得读锁的情况下不能再获得写锁）；读锁和写锁也是互斥的，也就是一个资源要么被上了一个写锁，要么被上了多个读锁，不会发生这个资即被上写锁又被上读锁的情况。

## 并发下集合类

并发集合类主要有：

- ConcurrentHashMap：支持多线程的分段哈希表，它通过将整个哈希表分成多段的方式减小锁粒度
- ConcurrentSkipListMap：ConcurrentSkipListMap的底层是通过跳表来实现的。跳表是一个链表，但是通过使用“跳跃式”查找的方式使得插入、读取数据时复杂度变成了O（logn）;
- ConCurrentSkipListSet：参考ConcurrentSkipListMap；
- CopyOnWriteArrayList：是ArrayList 的一个线程安全的变形，其中所有可变操作（添加、设置，等等）都是通过对基础数组进行一次新的复制来实现的; 
- CopyOnWriteArraySet：参考CopyOnWriteArrayList; 
-  ConcurrentLinkedQueue：cas实现的非阻塞并发队列;

## 线程池

### 介绍

多线程的设计优点是能很大限度的发挥多核处理器的计算能力，但是，若不控制好线程资源反而会拖累cpu，降低系统性能，这就涉及到了线程的回收复用等一系列问题；而且本身线程的创建和销毁也很耗费资源，因此找到一个合适的方法来提高线程的复用就很必要了。

线程池就是解决这类问题的一个很好的方法：线程池中本身有很多个线程，当需要使用线程的时候拿一个线程出来，当用完则还回去，而不是每次都创建和销毁。在JDK中提供了一套Executor线程池框架，帮助开发人员有效的进行线程控制。

### Executor使用

获得线程池的方法：

- newFixedThreadPool(int nThreads) ：创建固定数目线程的线程池；
- newCachedThreadPool：创建一个可缓存的线程池，调用execute将重用以前构造的线程（如果线程可用）。如果现有线程没有可用的，则创建一个新线 程并添加到池中；
- newSingleThreadExecutor：创建一个单线程化的Executor；
- newScheduledThreadPool：创建一个支持定时及周期性的任务执行的线程池。

以上方法都是返回一个ExecutorService对象，executorService.execute()传入一个Runnable对象，可执行一个线程任务

下面看示例代码

```java
public class Test implements Runnable{
	int i=0;
	public Test(int i){
		this.i=i;
	}
	public void run() {
		System.out.println(Thread.currentThread().getName()+"====="+i);
	}
    public static void main(String[] args) throws InterruptedException {
		ExecutorService cachedThreadPool = Executors.newCachedThreadPool();
		for(int i=0;i<10;i++){
			cachedThreadPool.execute(new Test(i));
			Thread.sleep(1000);
		}
	}
}

```

线程池是一个庞大而复杂的体系，本系列文章定位是基础，不对其做更深入的研究，感兴趣的小伙伴可以自行查资料进行学习。

### ScheduledExecutorService

newScheduledThreadPool(int corePoolSize)会返回一个ScheduledExecutorService对象，可以根据时间对线程进行调度；其下有三个执行线程任务的方法：schedule()，scheduleAtFixedRate()，scheduleWithFixedDelay()；该线程池可解决定时任务的问题。

示例：

```java
class Test implements Runnable {
    
    private String testStr;
    
    Test(String testStr) {
        this.testStr = testStr;
    }

    @Override
    public void run() {
        System.out.println(testStr + " >>>> print");
    }
    
    public static void main(String[] args) {
        ScheduledExecutorService service = Executors.newScheduledThreadPool(10);
        long wait = 1;
        long period = 1;
        service.scheduleAtFixedRate(new MyScheduledExecutor("job1"), wait, period, TimeUnit.SECONDS);
        service.scheduleWithFixedDelay(new MyScheduledExecutor("job2"), wait, period, TimeUnit.SECONDS);
        scheduledExecutorService.schedule(new MyScheduledExecutor("job3"), wait, TimeUnit.SECONDS);//延时waits 执行
    }
}
```

job1的执行方式是任务发起后间隔`wait`秒开始执行，每隔`period`秒(注意：不包括上一个线程的执行时间)执行一次；

job2的执行方式是任务发起后间隔`wait`秒开始执行，等线程结束后隔`period`秒开始执行下一个线程；

job3只执行一次，延迟`wait`秒执行；

ScheduledExecutorService还可以配合Callable使用来回调获得线程执行结果，还可以取消队列中的执行任务等操作，这属于比较复杂的用法，我们这里掌握基本的即可，到实际遇到相应的问题时我们在现学现用，节省学习成本。