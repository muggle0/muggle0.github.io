---
title: 一起来学redis redission
date: 2022-06-07 11:22:11
tags: redis
---

redis 的客户端有jedis、lettuce、redission；我个人比较推荐的是redission，因为它的分布式锁和缓存实在是太优秀了。 Redisson采用了基于NIO的Netty框架，封装了大家常用的集合类以及原子类、锁等工具。
本章节主要介绍redission 中重要的两个点：数据结构和锁

本章节主要介绍redission 中重要的两个点：数据结构和锁

## map

基于Redis的Redisson的分布式映射结构的RMap Java对象实现了java.util.concurrent.ConcurrentMap接口和java.util.Map接口。与HashMap不同的是，RMap保持了元素的插入顺序。
在特定的场景下，映射缓存（Map）上的高度频繁的读取操作，使网络通信都被视为瓶颈时，可以使用Redisson提供的带有本地缓存功能的映射。

代码示例：

```
RMap<String, SomeObject> map = redisson.getMap("anyMap");
SomeObject prevObject = map.put("123", new SomeObject());
SomeObject currentObject = map.putIfAbsent("323", new SomeObject());
SomeObject obj = map.remove("123");

map.fastPut("321", new SomeObject());
map.fastRemove("321");

RFuture<SomeObject> putAsyncFuture = map.putAsync("321");
RFuture<Void> fastPutAsyncFuture = map.fastPutAsync("321");

map.fastPutAsync("321", new SomeObject());
map.fastRemoveAsync("321");
```

map本身也是可以上锁的：

```
RMap<MyKey, MyValue> map = redisson.getMap("anyMap");
MyKey k = new MyKey();
RLock keyLock = map.getLock(k);
keyLock.lock();
try {
   MyValue v = map.get(k);
   // 其他业务逻辑
} finally {
   keyLock.unlock();
}

RReadWriteLock rwLock = map.getReadWriteLock(k);
rwLock.readLock().lock();
try {
   MyValue v = map.get(k);
   // 其他业务逻辑
} finally {
   keyLock.readLock().unlock();
}
```
map中还有元素淘汰，本地缓存和数据分片等机制相关类：

- 元素淘汰（Eviction） 类 -- 带有元素淘汰（Eviction）机制的映射类允许针对一个映射中每个元素单独设定 有效时间 和 最长闲置时间 。

- 本地缓存（LocalCache） 类 -- 本地缓存（Local Cache）也叫就近缓存（Near Cache）。这类映射的使用主要用于在特定的场景下，映射缓存（MapCache）上的高度频繁的读取操作，使网络通信都被视为瓶颈的情况。Redisson与Redis通信的同时，还将部分数据保存在本地内存里。这样的设计的好处是它能将读取速度提高最多 45倍 。 所有同名的本地缓存共用一个订阅发布话题，所有更新和过期消息都将通过该话题共享。

- 数据分片（Sharding） 类 -- 数据分片（Sharding）类仅适用于Redis集群环境下，因此带有数据分片（Sharding）功能的映射也叫集群分布式映射。它利用分库的原理，将单一一个映射结构切分为若干个小的映射，并均匀的分布在集群中的各个槽里。这样的设计能使一个单一映射结构突破Redis自身的容量限制，让其容量随集群的扩大而增长。在扩容的同时，还能够使读写性能和元素淘汰处理能力随之成线性增长。

map 类：
![](images/2022-06-07-15-55-36.png)

Redisson的分布式的RMapCache Java对象在基于RMap的前提下实现了针对单个元素的淘汰机制，这种功能是其他两个redis客户端所不能具备的。
Redis自身并不支持散列（Hash）当中的元素淘汰，因此所有过期元素都是通过org.redisson.EvictionScheduler实例来实现定期清理的。为了保证资源的有效利用，每次运行最多清理300个过期元素。任务的启动时间将根据上次实际清理数量自动调整，间隔时间趋于1秒到1小时之间。比如该次清理时删除了300条元素，那么下次执行清理的时间将在1秒以后（最小间隔时间）。一旦该次清理数量少于上次清理数量，时间间隔将增加1.5倍。

```
RMapCache<String, SomeObject> map = redisson.getMapCache("anyMap");
// 有效时间 ttl = 10分钟
map.put("key1", new SomeObject(), 10, TimeUnit.MINUTES);
// 有效时间 ttl = 10分钟, 最长闲置时间 maxIdleTime = 10秒钟
map.put("key1", new SomeObject(), 10, TimeUnit.MINUTES, 10, TimeUnit.SECONDS);

// 有效时间 = 3 秒钟
map.putIfAbsent("key2", new SomeObject(), 3, TimeUnit.SECONDS);
// 有效时间 ttl = 40秒钟, 最长闲置时间 maxIdleTime = 10秒钟
map.putIfAbsent("key2", new SomeObject(), 40, TimeUnit.SECONDS, 10, TimeUnit.SECONDS);
```

本地缓存功能充分的利用了JVM的自身内存空间，对部分常用的元素实行就地缓存，这样的设计让读取操作的性能较分布式映射相比提高最多 45倍 。以下配置参数可以用来创建这个实例：

```
LocalCachedMapOptions options = LocalCachedMapOptions.defaults()
      // 用于淘汰清除本地缓存内的元素
      // 共有以下几种选择:
      // LFU - 统计元素的使用频率，淘汰用得最少（最不常用）的。
      // LRU - 按元素使用时间排序比较，淘汰最早（最久远）的。
      // SOFT - 元素用Java的WeakReference来保存，缓存元素通过GC过程清除。
      // WEAK - 元素用Java的SoftReference来保存, 缓存元素通过GC过程清除。
      // NONE - 永不淘汰清除缓存元素。
     .evictionPolicy(EvictionPolicy.NONE)
     // 如果缓存容量值为0表示不限制本地缓存容量大小
     .cacheSize(1000)
      // 以下选项适用于断线原因造成了未收到本地缓存更新消息的情况。
      // 断线重连的策略有以下几种：
      // CLEAR - 如果断线一段时间以后则在重新建立连接以后清空本地缓存
      // LOAD - 在服务端保存一份10分钟的作废日志
      //        如果10分钟内重新建立连接，则按照作废日志内的记录清空本地缓存的元素
      //        如果断线时间超过了这个时间，则将清空本地缓存中所有的内容
      // NONE - 默认值。断线重连时不做处理。
     .reconnectionStrategy(ReconnectionStrategy.NONE)
      // 以下选项适用于不同本地缓存之间相互保持同步的情况
      // 缓存同步策略有以下几种：
      // INVALIDATE - 默认值。当本地缓存映射的某条元素发生变动时，同时驱逐所有相同本地缓存映射内的该元素
      // UPDATE - 当本地缓存映射的某条元素发生变动时，同时更新所有相同本地缓存映射内的该元素
      // NONE - 不做任何同步处理
     .syncStrategy(SyncStrategy.INVALIDATE)
      // 每个Map本地缓存里元素的有效时间，默认毫秒为单位
     .timeToLive(10000)
      // 或者
     .timeToLive(10, TimeUnit.SECONDS)
      // 每个Map本地缓存里元素的最长闲置时间，默认毫秒为单位
     .maxIdle(10000)
      // 或者
     .maxIdle(10, TimeUnit.SECONDS);

     RLocalCachedMap<String, Integer> map = redisson.getLocalCachedMap("test", options);

String prevObject = map.put("123", 1);
String currentObject = map.putIfAbsent("323", 2);
String obj = map.remove("123");

// 在不需要旧值的情况下可以使用fast为前缀的类似方法
map.fastPut("a", 1);
map.fastPutIfAbsent("d", 32);
map.fastRemove("b");

RFuture<String> putAsyncFuture = map.putAsync("321");
RFuture<Void> fastPutAsyncFuture = map.fastPutAsync("321");

map.fastPutAsync("321", new SomeObject());
map.fastRemoveAsync("321");
// 当不再使用Map本地缓存对象的时候应该手动销毁，如果Redisson对象被关闭（shutdown）了，则不用手动销毁。
map.destroy();
```

RClusteredMap 分片map使用示例：
```
RClusteredMap<String, SomeObject> map = redisson.getClusteredMap("anyMap");

SomeObject prevObject = map.put("123", new SomeObject());
SomeObject currentObject = map.putIfAbsent("323", new SomeObject());
SomeObject obj = map.remove("123");

map.fastPut("321", new SomeObject());
map.fastRemove("321");
```

映射监听器（Map Listener）可以监听map的活动，代码示例：

```
RMapCache<String, Integer> map = redisson.getMapCache("myMap");
// 或
RLocalCachedMapCache<String, Integer> map = redisson.getLocalCachedMapCache("myMap", options);

int updateListener = map.addListener(new EntryUpdatedListener<Integer, Integer>() {
     @Override
     public void onUpdated(EntryEvent<Integer, Integer> event) {
          event.getKey(); // 字段名
          event.getValue() // 新值
          event.getOldValue() // 旧值
          // ...
     }
});

int createListener = map.addListener(new EntryCreatedListener<Integer, Integer>() {
     @Override
     public void onCreated(EntryEvent<Integer, Integer> event) {
          event.getKey(); // 字段名
          event.getValue() // 值
          // ...
     }
});

int expireListener = map.addListener(new EntryExpiredListener<Integer, Integer>() {
     @Override
     public void onExpired(EntryEvent<Integer, Integer> event) {
          event.getKey(); // 字段名
          event.getValue() // 值
          // ...
     }
});

int removeListener = map.addListener(new EntryRemovedListener<Integer, Integer>() {
     @Override
     public void onRemoved(EntryEvent<Integer, Integer> event) {
          event.getKey(); // 字段名
          event.getValue() // 值
          // ...
     }
});

map.removeListener(updateListener);
map.removeListener(createListener);
map.removeListener(expireListener);
map.removeListener(removeListener);
```

## Set

代码示例：
```
RSet<SomeObject> set = redisson.getSet("anySet");
set.add(new SomeObject());
set.remove(new SomeObject());
```

基于Redis的Redisson的分布式RSetCache Java对象在基于RSet的前提下实现了针对单个元素的淘汰机制。和map 一样，所有过期元素都是通过org.redisson.EvictionScheduler实例来实现定期清理的。代码示例：

```
RSetCache<SomeObject> set = redisson.getSetCache("anySet");
// ttl = 10 seconds
set.add(new SomeObject(), 10, TimeUnit.SECONDS);
```

分布式RClusteredSet:

```
RClusteredSet<SomeObject> set = redisson.getClusteredSet("anySet");
set.add(new SomeObject());
set.remove(new SomeObject());
```

有序集（SortedSet):

```
RSortedSet<Integer> set = redisson.getSortedSet("anySet");
set.trySetComparator(new MyComparator()); // 配置元素比较器
set.add(3);
set.add(1);
set.add(2);

set.removeAsync(0);
set.addAsync(5);
```

计分排序集（ScoredSortedSet)是一个可以按插入时指定的元素评分排序的集合:
```
RScoredSortedSet<SomeObject> set = redisson.getScoredSortedSet("simple");

set.add(0.13, new SomeObject(a, b));
set.addAsync(0.251, new SomeObject(c, d));
set.add(0.302, new SomeObject(g, d));

set.pollFirst();
set.pollLast();

int index = set.rank(new SomeObject(g, d)); // 获取元素在集合中的位置
Double score = set.getScore(new SomeObject(g, d)); // 获取元素的评分
```

## List

RList 示例：

```
RList<SomeObject> list = redisson.getList("anyList");
list.add(new SomeObject());
list.get(0);
list.remove(new SomeObject());
```

## Queue

无界队列Queue：
```
RQueue<SomeObject> queue = redisson.getQueue("anyQueue");
queue.add(new SomeObject());
SomeObject obj = queue.peek();
SomeObject someObj = queue.poll();
```

双端队列（Deque）:
```
RDeque<SomeObject> queue = redisson.getDeque("anyDeque");
queue.addFirst(new SomeObject());
queue.addLast(new SomeObject());
SomeObject obj = queue.removeFirst();
SomeObject someObj = queue.removeLast();
```

阻塞队列（Blocking Queue）：
```
RBlockingQueue<SomeObject> queue = redisson.getBlockingQueue("anyQueue");
queue.offer(new SomeObject());

SomeObject obj = queue.peek();
SomeObject someObj = queue.poll();
SomeObject ob = queue.poll(10, TimeUnit.MINUTES);
```
有界阻塞队列（Bounded Blocking Queue）:

```
RBoundedBlockingQueue<SomeObject> queue = redisson.getBoundedBlockingQueue("anyQueue");
// 如果初始容量（边界）设定成功则返回`真（true）`，
// 如果初始容量（边界）已近存在则返回`假（false）`。
queue.trySetCapacity(2);

queue.offer(new SomeObject(1));
queue.offer(new SomeObject(2));
// 此时容量已满，下面代码将会被阻塞，直到有空闲为止。
queue.put(new SomeObject());

SomeObject obj = queue.peek();
SomeObject someObj = queue.poll();
SomeObject ob = queue.poll(10, TimeUnit.MINUTES);
```

阻塞双端队列（Blocking Deque）:
```
RBlockingDeque<Integer> deque = redisson.getBlockingDeque("anyDeque");
deque.putFirst(1);
deque.putLast(2);
Integer firstValue = queue.takeFirst();
Integer lastValue = queue.takeLast();
Integer firstValue = queue.pollFirst(10, TimeUnit.MINUTES);
Integer lastValue = queue.pollLast(3, TimeUnit.MINUTES);
```

阻塞公平队列（Blocking Fair Queue）：
```
RBlockingFairQueue queue = redisson.getBlockingFairQueue("myQueue");
queue.offer(new SomeObject());

SomeObject obj = queue.peek();
SomeObject someObj = queue.poll();
SomeObject ob = queue.poll(10, TimeUnit.MINUTES);
```

阻塞公平双端队列（Blocking Fair Deque）:
```
RBlockingFairDeque deque = redisson.getBlockingFairDeque("myDeque");
deque.offer(new SomeObject());

SomeObject firstElement = queue.peekFirst();
SomeObject firstElement = queue.pollFirst();
SomeObject firstElement = queue.pollFirst(10, TimeUnit.MINUTES);
SomeObject firstElement = queue.takeFirst();

SomeObject lastElement = queue.peekLast();
SomeObject lastElement = queue.pollLast();
SomeObject lastElement = queue.pollLast(10, TimeUnit.MINUTES);
SomeObject lastElement = queue.takeLast();
```

 延迟队列（Delayed Queue）:
 ```
 RQueue<String> distinationQueue = ...
RDelayedQueue<String> delayedQueue = getDelayedQueue(distinationQueue);
// 10秒钟以后将消息发送到指定队列
delayedQueue.offer("msg1", 10, TimeUnit.SECONDS);
// 一分钟以后将消息发送到指定队列
delayedQueue.offer("msg2", 1, TimeUnit.MINUTES);

// 在该对象不再需要的情况下，应该主动销毁。仅在相关的Redisson对象也需要关闭的时候可以不用主动销毁。
delayedQueue.destroy();
 ```
 优先队列（Priority Queue）,可以通过比较器（Comparator）接口来对元素排序:

 ```
 RPriorityQueue<Integer> queue = redisson.getPriorityQueue("anyQueue");
queue.trySetComparator(new MyComparator()); // 指定对象比较器
queue.add(3);
queue.add(1);
queue.add(2);

queue.removeAsync(0);
queue.addAsync(5);

queue.poll();
 ```

## 看门狗

如果负责储存分布式锁的Redisson节点宕机以后，而且这个锁正好处于锁住的状态时，这个锁会出现锁死的状态。为了避免这种情况的发生，Redisson内部提供了一个监控锁的看门狗，它的作用是在Redisson实例被关闭前，不断的延长锁的有效期，默认情况下，看门狗的检查锁的超时时间是30秒钟，也可以通过修改Config.lockWatchdogTimeout来另行指定。

 ## 可重入锁（Reentrant Lock）

 ```
 RLock lock = redisson.getLock("anyLock");
// 最常见的使用方法
lock.lock();
 ```
 Redisson还通过加锁的方法提供了leaseTime的参数来指定加锁的时间。超过这个时间后锁便自动解开:

 ```
 // 加锁以后10秒钟自动解锁
// 无需调用unlock方法手动解锁
lock.lock(10, TimeUnit.SECONDS);

// 尝试加锁，最多等待100秒，上锁以后10秒自动解锁
boolean res = lock.tryLock(100, 10, TimeUnit.SECONDS);
if (res) {
   try {
     ...
   } finally {
       lock.unlock();
   }
}
 ```

 异步执行：
 ```
 RLock lock = redisson.getLock("anyLock");
lock.lockAsync();
lock.lockAsync(10, TimeUnit.SECONDS);
Future<Boolean> res = lock.tryLockAsync(100, 10, TimeUnit.SECONDS);

 ```

 ## 公平锁（Fair Lock）

 当多个Redisson客户端线程同时请求加锁时，优先分配给先发出请求的线程,所有请求线程会在一个队列中排队。当某个线程出现宕机，Redisson会等待5秒后继续下一个线程：
 ```
 RLock fairLock = redisson.getFairLock("anyLock");
// 最常见的使用方法
fairLock.lock();
 ```

 ## 联锁（MultiLock）

 基于Redis的Redisson分布式联锁RedissonMultiLock对象可以将多个RLock对象关联为一个联锁，每个RLock对象实例可以来自于不同的Redisson实例:

 ```
 RLock lock1 = redissonInstance1.getLock("lock1");
RLock lock2 = redissonInstance2.getLock("lock2");
RLock lock3 = redissonInstance3.getLock("lock3");

RedissonMultiLock lock = new RedissonMultiLock(lock1, lock2, lock3);
// 同时加锁：lock1 lock2 lock3
// 所有的锁都上锁成功才算成功。
lock.lock();
...
lock.unlock();
 ```

 ## 红锁（RedLock）
 红锁RedissonRedLock对象可以用来将多个RLock对象关联为一个红锁，每个RLock对象实例可以来自于不同的Redisson实例：

 ```
 RLock lock1 = redissonInstance1.getLock("lock1");
RLock lock2 = redissonInstance2.getLock("lock2");
RLock lock3 = redissonInstance3.getLock("lock3");

RedissonRedLock lock = new RedissonRedLock(lock1, lock2, lock3);
// 同时加锁：lock1 lock2 lock3
// 红锁在大部分节点上加锁成功就算成功。
lock.lock();
...
lock.unlock();
```

## 信号量（Semaphore）

同JDK中的信号量：

```
RSemaphore semaphore = redisson.getSemaphore("semaphore");
semaphore.acquire();
//或
semaphore.acquireAsync();
semaphore.acquire(23);
semaphore.tryAcquire();
//或
semaphore.tryAcquireAsync();
semaphore.tryAcquire(23, TimeUnit.SECONDS);
//或
semaphore.tryAcquireAsync(23, TimeUnit.SECONDS);
semaphore.release(10);
semaphore.release();
//或
semaphore.releaseAsync();
```
可过期信号量，是在RSemaphore对象的基础上，为每个信号增加了一个过期时间：

```
RPermitExpirableSemaphore semaphore = redisson.getPermitExpirableSemaphore("mySemaphore");
String permitId = semaphore.acquire();
// 获取一个信号，有效期只有2秒钟。
String permitId = semaphore.acquire(2, TimeUnit.SECONDS);
// ...
semaphore.release(permitId);
```

## 闭锁（CountDownLatch）

同jdk中的闭锁：

```
RCountDownLatch latch = redisson.getCountDownLatch("anyCountDownLatch");
latch.trySetCount(1);
latch.await();

// 在其他线程或其他JVM里
RCountDownLatch latch = redisson.getCountDownLatch("anyCountDownLatch");
latch.countDown();
```

