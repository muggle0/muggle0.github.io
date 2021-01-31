---
title: 多线程编程进阶篇
date: 2019-04-23 09:24:43
tags: thread
---

作者：muggle

 ## 锁优化

### 减小锁持有时间

减小锁的持有时间可有效的减少锁的竞争。如果线程持有锁的时间越长，那么锁的竞争程度就会越激烈。因此，应尽可能减少线程对某个锁的占有时间，进而减少线程间互斥的可能。

减少锁持有时间的方法有：

- 进行条件判断，只对必要的情况进行加锁，而不是整个方法加锁；
- 减少加锁代码的行数，只对必要的步骤加锁。

<!--more-->

### 减小锁粒度

减小锁的范围，减少锁住的代码行数可减少锁范围，减小共享资源的范围也可减小锁的范围。减小锁共享资源的范围的方式比较常见的有分段锁，比如`ConcurrentHashMap`，它将数据分为了多段，当需要put元素的时候，并不是对整个hashmap进行加锁，而是先通过hashcode来知道他要放在那一个分段中，然后对这个分段进行加锁，所以当多线程put的时候，只要不是放在一个分段中，就实现了真正的并行的插入。

### 锁分离 

锁分离最常见的操作就是读写分离了，读写分离的操作参考**ReadWriteLock**章节，而对读写分离进一步的延伸就是锁分离了。为了提高线程的并行量，我们可以针对不同的功能（情形）采用不同的锁，而不是统统用同一把锁。比如说有一个同步方法未进行锁分离之前，它只有一把锁，任何线程来了，只有拿到锁才有资格运行；进行锁分离之后就不是这种情形了——来一个线程，先判断一下它要干嘛，然后发一个对应的锁给它，这样就能一定程度上提高线程的并行数。

### 锁粗化

一般为了保证多线程间的有效并发，会要求每个线程持有锁的时间尽量短，也就是说锁住的代码尽量少。但是如果如果对同一个锁不停的进行请求、同步和释放，其本身也会消耗系统宝贵的资源，反而不利于性能的优化 。比如有三个步骤：a、b、c，a同步，b不同步，c同步；那么一个线程来时候会上锁释放锁然后又上锁释放锁。这样反而可能会降低线程的执行效率，这个时候我们可能将锁粗化可能会更好——执行a的时候上锁，执行完c再释放锁

## 锁扩展

### 分布式锁

jdk提供的锁在单体项目中不会有什么问题，但是在集群项目中就会有问题了。在分布式模型下，数据只有一份（或有限制），此时需要利用锁的技术控制某一时刻修改数据的进程数。jdk锁显然无法满足我们的需求，于是就有了分布式锁。

分布式锁的实现有三种方式：

- 基于数据库实现分布式锁
- 基于缓存（redis，memcached，tair）实现分布式锁 
- 基于Zookeeper实现分布式锁

基于redis的分布式锁比较使用普遍，在这里介绍其原理和使用。redis实现锁的机制是setnx指令，setnx是原子操作命令，锁存在不能设置值，返回0；锁不存在，则设置锁，返回1，根据返回值来判断上锁是否成功。看到这里你可能想为啥不先get有没有值，再set上锁；首先我们要知道，redis是单线程的，同一时刻只有可能有一个线程操作内存，然后setnx 是一个操作步骤(具有原子性)，而get再set是两个步骤（不具有原子性）。如果使用第二种可能会发生这种情况：客户端 a get发现没有锁，这个时候被切换到客户端b，b get也发现没锁，然后b set，这个时候又切换到a客户端 a set；这种情况下，锁完全没起作用。所以，redis分布式锁，原子性是关键。

对于web应用中redis客户端用的比较多的是lettuce，jedis，redisson。springboot的redis的start包底层是lettuce，但对redis分布式锁支持得最好的是redisson（如果用redisson你就享受不到redis自动化配置的好处了）；不过springboot的redisTemplete支持手写lua脚本，我们可以通过手写lua脚本来实现redis锁

代码示例：

```java
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

关于lua脚本的语法我就不做介绍了。

在github上也有开源的redis锁项目，比如[spring-boot-klock-starter](https://github.com/kekingcn/spring-boot-klock-starter) 感兴趣的小伙伴可以去试用一下。

### 数据库锁     

对于存在多线程问题的项目，比如商品货物的进销存，订单系统单据流转这种，我们可以通过代码上锁来控制并发，也可以使用数据库锁来控制并发，数据库锁从机制上来说分数据库锁分乐观锁和悲观锁。

悲观锁：

悲观锁分为共享锁（S锁）和排他锁（X锁），mysql数据库读操作分为三种——快照读，当前读；快照读就是普通的读操作，如：

```sql
select *from table
```

当前读就是对数据库上悲观锁了；其中

```sql
select ... lock in share mode
```

属于共享锁，多个事务对于同一数据可以共享，但只能读不能修改。而下面三种sql

```sql
select ...for update
update ... set...
insert into ...
```

属于排他锁，排他锁就是不能与其他所并存，如一个事务获取了一个数据行的排他锁，其他事务就不能再获取该行的其他锁，包括共享锁和排他锁，但是获取排他锁的事务是可以对数据就行读取和修改，排他锁是阻塞锁。

乐观锁：

就是很乐观，每次去拿数据的时候都认为别人不会修改，所以不会上锁，但是在更新的时候会判断一下在此期间别人有没有去更新这个数据，如果有则更新失败。一种实现方式为在数据库表中加一个版本号字段version，任何update语句where 后面都要跟上version=？，并且每次update版本号都加1。如果a线程要修改某条数据，它需要先select快照读获得版本号，然后update，同时版本号加一。这样就保证了在a线程修改某条数据的时候，确保其他线程没有修改过这条数据，一旦其他线程修改过，就会导致a线程版本号对不上而更新失败（这其实是一个简化版的mvcc）。

乐观锁适用于允许更新失败的业务场景，悲观锁适用于确保更新操作被执行的场景。

## 并发编程相关

- 善用java 8 Stream
- 对于生产者消费者模式，条件判断是使用while而不是if
- 懒汉单例采用双重检查和锁保证线程安全
- 善用Future模式
- 合理使用ThreadLocal

java8引入lambda表达式使在java中使用函数式编程很方便。而java8中的stream对数据的处理能使线程执行速度得以优化。Future模式是一种对异步线程的回调机制；现在cpu都是多核的，我们在处理一些较为费时的任务时可使用异步，在后台开启多个线程同时处理，等到异步线程处理完再通过Future回调拿到处理的结果。

ThreadLocal的实例代表了一个线程局部的变量，每条线程都只能看到自己的值，并不会意识到其它的线程中也存在该变量(这里原理就不说了，网上资料很多)，总之就是我们如果想在多线程的类里面使用线程安全的变量就用ThreadLocal。但是请一定要注意**用完记得remove**，不然会发生内存泄漏。

## 总结

随着后端发展，现在单体项目越来越少，基本上都是集群和分布式，这样也使得jdk的锁慢慢变得无用武之地。但是万变不离其宗，虽然锁的实现方式变了，但其机制是没变的；无论是分布式锁还是jdk锁，其目的和处理方式都是一个机制，只是处理对象不一样而已。

我们在平时编写程序时对多线程最应该注意的就是线程优化和锁问题。我们脑中要对锁机制有一套体系，而对线程的优化经验在于平时的积累和留心。

