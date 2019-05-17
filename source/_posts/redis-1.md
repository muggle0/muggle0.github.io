---
title: redis笔记
date: 2019-05-06 09:53:26
tags: developing
---

## redis基础知识

客户端与服务端的通讯协议是建立在TCP协议之上构建的；

redis序列化协议 resp

- 状态回复（status reply）的第一个字节是 `"+"`
- 错误回复（error reply）的第一个字节是 `"-"`
- 整数回复（integer reply）的第一个字节是 `":"`
- 批量回复（bulk reply）的第一个字节是 `"$"`
- 多条批量回复（multi bulk reply）的第一个字节是 `"*"`

<!--more-->

举例：

```shell
SET mykey myvalue
*3\r\n$3\r\nSET\r\n$5\r\mykey\r\n$7\r\myvalue\r\n
```

指令表：

[redis命令表](<http://redisdoc.com/>)

- 字符串
  - [SET](http://redisdoc.com/string/set.html)
  - [SETNX](http://redisdoc.com/string/setnx.html)
  - [SETEX](http://redisdoc.com/string/setex.html)
  - [PSETEX](http://redisdoc.com/string/psetex.html)
  - [GET](http://redisdoc.com/string/get.html)
  - [GETSET](http://redisdoc.com/string/getset.html)
  - [STRLEN](http://redisdoc.com/string/strlen.html)
  - [APPEND](http://redisdoc.com/string/append.html)
  - [SETRANGE](http://redisdoc.com/string/setrange.html)
  - [GETRANGE](http://redisdoc.com/string/getrange.html)
  - [INCR](http://redisdoc.com/string/incr.html)
  - [INCRBY](http://redisdoc.com/string/incrby.html)
  - [INCRBYFLOAT](http://redisdoc.com/string/incrbyfloat.html)
  - [DECR](http://redisdoc.com/string/decr.html)
  - [DECRBY](http://redisdoc.com/string/decrby.html)
  - [MSET](http://redisdoc.com/string/mset.html)
  - [MSETNX](http://redisdoc.com/string/msetnx.html)
  - [MGET](http://redisdoc.com/string/mget.html)
- 哈希表
  - [HSET](http://redisdoc.com/hash/hset.html)
  - [HSETNX](http://redisdoc.com/hash/hsetnx.html)
  - [HGET](http://redisdoc.com/hash/hget.html)
  - [HEXISTS](http://redisdoc.com/hash/hexists.html)
  - [HDEL](http://redisdoc.com/hash/hdel.html)
  - [HLEN](http://redisdoc.com/hash/hlen.html)
  - [HSTRLEN](http://redisdoc.com/hash/hstrlen.html)
  - [HINCRBY](http://redisdoc.com/hash/hincrby.html)
  - [HINCRBYFLOAT](http://redisdoc.com/hash/hincrbyfloat.html)
  - [HMSET](http://redisdoc.com/hash/hmset.html)
  - [HMGET](http://redisdoc.com/hash/hmget.html)
  - [HKEYS](http://redisdoc.com/hash/hkeys.html)
  - [HVALS](http://redisdoc.com/hash/hvals.html)
  - [HGETALL](http://redisdoc.com/hash/hgetall.html)
  - [HSCAN](http://redisdoc.com/hash/hscan.html)
- 列表
  - [LPUSH](http://redisdoc.com/list/lpush.html)
  - [LPUSHX](http://redisdoc.com/list/lpushx.html)
  - [RPUSH](http://redisdoc.com/list/rpush.html)
  - [RPUSHX](http://redisdoc.com/list/rpushx.html)
  - [LPOP](http://redisdoc.com/list/lpop.html)
  - [RPOP](http://redisdoc.com/list/rpop.html)
  - [RPOPLPUSH](http://redisdoc.com/list/rpoplpush.html)
  - [LREM](http://redisdoc.com/list/lrem.html)
  - [LLEN](http://redisdoc.com/list/llen.html)
  - [LINDEX](http://redisdoc.com/list/lindex.html)
  - [LINSERT](http://redisdoc.com/list/linsert.html)
  - [LSET](http://redisdoc.com/list/lset.html)
  - [LRANGE](http://redisdoc.com/list/lrange.html)
  - [LTRIM](http://redisdoc.com/list/ltrim.html)
  - [BLPOP](http://redisdoc.com/list/blpop.html)
  - [BRPOP](http://redisdoc.com/list/brpop.html)
  - [BRPOPLPUSH](http://redisdoc.com/list/brpoplpush.html)
- 集合
  - [SADD](http://redisdoc.com/set/sadd.html)
  - [SISMEMBER](http://redisdoc.com/set/sismember.html)
  - [SPOP](http://redisdoc.com/set/spop.html)
  - [SRANDMEMBER](http://redisdoc.com/set/srandmember.html)
  - [SREM](http://redisdoc.com/set/srem.html)
  - [SMOVE](http://redisdoc.com/set/smove.html)
  - [SCARD](http://redisdoc.com/set/scard.html)
  - [SMEMBERS](http://redisdoc.com/set/smembers.html)
  - [SSCAN](http://redisdoc.com/set/sscan.html)
  - [SINTER](http://redisdoc.com/set/sinter.html)
  - [SINTERSTORE](http://redisdoc.com/set/sinterstore.html)
  - [SUNION](http://redisdoc.com/set/sunion.html)
  - [SUNIONSTORE](http://redisdoc.com/set/sunionstore.html)
  - [SDIFF](http://redisdoc.com/set/sdiff.html)
  - [SDIFFSTORE](http://redisdoc.com/set/sdiffstore.html)
- 有序集合
  - [ZADD](http://redisdoc.com/sorted_set/zadd.html)
  - [ZSCORE](http://redisdoc.com/sorted_set/zscore.html)
  - [ZINCRBY](http://redisdoc.com/sorted_set/zincrby.html)
  - [ZCARD](http://redisdoc.com/sorted_set/zcard.html)
  - [ZCOUNT](http://redisdoc.com/sorted_set/zcount.html)
  - [ZRANGE](http://redisdoc.com/sorted_set/zrange.html)
  - [ZREVRANGE](http://redisdoc.com/sorted_set/zrevrange.html)
  - [ZRANGEBYSCORE](http://redisdoc.com/sorted_set/zrangebyscore.html)
  - [ZREVRANGEBYSCORE](http://redisdoc.com/sorted_set/zrevrangebyscore.html)
  - [ZRANK](http://redisdoc.com/sorted_set/zrank.html)
  - [ZREVRANK](http://redisdoc.com/sorted_set/zrevrank.html)
  - [ZREM](http://redisdoc.com/sorted_set/zrem.html)
  - [ZREMRANGEBYRANK](http://redisdoc.com/sorted_set/zremrangebyrank.html)
  - [ZREMRANGEBYSCORE](http://redisdoc.com/sorted_set/zremrangebyscore.html)
  - [ZRANGEBYLEX](http://redisdoc.com/sorted_set/zrangebylex.html)
  - [ZLEXCOUNT](http://redisdoc.com/sorted_set/zlexcount.html)
  - [ZREMRANGEBYLEX](http://redisdoc.com/sorted_set/zremrangebylex.html)
  - [ZSCAN](http://redisdoc.com/sorted_set/zscan.html)
  - [ZUNIONSTORE](http://redisdoc.com/sorted_set/zunionstore.html)
  - [ZINTERSTORE](http://redisdoc.com/sorted_set/zinterstore.html)
- HyperLogLog
  - [PFADD](http://redisdoc.com/hyperloglog/pfadd.html)
  - [PFCOUNT](http://redisdoc.com/hyperloglog/pfcount.html)
  - [PFMERGE](http://redisdoc.com/hyperloglog/pfmerge.html)
- 地理位置
  - [GEOADD](http://redisdoc.com/geo/geoadd.html)
  - [GEOPOS](http://redisdoc.com/geo/geopos.html)
  - [GEODIST](http://redisdoc.com/geo/geodist.html)
  - [GEORADIUS](http://redisdoc.com/geo/georadius.html)
  - [GEORADIUSBYMEMBER](http://redisdoc.com/geo/georadiusbymember.html)
  - [GEOHASH](http://redisdoc.com/geo/geohash.html)
- 位图
  - [SETBIT](http://redisdoc.com/bitmap/setbit.html)
  - [GETBIT](http://redisdoc.com/bitmap/getbit.html)
  - [BITCOUNT](http://redisdoc.com/bitmap/bitcount.html)
  - [BITPOS](http://redisdoc.com/bitmap/bitpos.html)
  - [BITOP](http://redisdoc.com/bitmap/bitop.html)
  - [BITFIELD](http://redisdoc.com/bitmap/bitfield.html)
- 数据库
  - [EXISTS](http://redisdoc.com/database/exists.html)
  - [TYPE](http://redisdoc.com/database/type.html)
  - [RENAME](http://redisdoc.com/database/rename.html)
  - [RENAMENX](http://redisdoc.com/database/renamenx.html)
  - [MOVE](http://redisdoc.com/database/move.html)
  - [DEL](http://redisdoc.com/database/del.html)
  - [RANDOMKEY](http://redisdoc.com/database/randomkey.html)
  - [DBSIZE](http://redisdoc.com/database/dbsize.html)
  - [KEYS](http://redisdoc.com/database/keys.html)
  - [SCAN](http://redisdoc.com/database/scan.html)
  - [SORT](http://redisdoc.com/database/sort.html)
  - [FLUSHDB](http://redisdoc.com/database/flushdb.html)
  - [FLUSHALL](http://redisdoc.com/database/flushall.html)
  - [SELECT](http://redisdoc.com/database/select.html)
  - [SWAPDB](http://redisdoc.com/database/swapdb.html)
- 自动过期
  - [EXPIRE](http://redisdoc.com/expire/expire.html)
  - [EXPIREAT](http://redisdoc.com/expire/expireat.html)
  - [TTL](http://redisdoc.com/expire/ttl.html)
  - [PERSIST](http://redisdoc.com/expire/persist.html)
  - [PEXPIRE](http://redisdoc.com/expire/pexpire.html)
  - [PEXPIREAT](http://redisdoc.com/expire/pexpireat.html)
  - [PTTL](http://redisdoc.com/expire/pttl.html)
- 事务
  - [MULTI](http://redisdoc.com/transaction/multi.html)
  - [EXEC](http://redisdoc.com/transaction/exec.html)
  - [DISCARD](http://redisdoc.com/transaction/discard.html)
  - [WATCH](http://redisdoc.com/transaction/watch.html)
  - [UNWATCH](http://redisdoc.com/transaction/unwatch.html)
- Lua 脚本
  - [EVAL](http://redisdoc.com/script/eval.html)
  - [EVALSHA](http://redisdoc.com/script/evalsha.html)
  - [SCRIPT_LOAD](http://redisdoc.com/script/script_load.html)
  - [SCRIPT_EXISTS](http://redisdoc.com/script/script_exists.html)
  - [SCRIPT_FLUSH](http://redisdoc.com/script/script_flush.html)
  - [SCRIPT_KILL](http://redisdoc.com/script/script_kill.html)
- 持久化
  - [SAVE](http://redisdoc.com/persistence/save.html)
  - [BGSAVE](http://redisdoc.com/persistence/bgsave.html)
  - [BGREWRITEAOF](http://redisdoc.com/persistence/bgrewriteaof.html)
  - [LASTSAVE](http://redisdoc.com/persistence/lastsave.html)
- 发布与订阅
  - [PUBLISH](http://redisdoc.com/pubsub/publish.html)
  - [SUBSCRIBE](http://redisdoc.com/pubsub/subscribe.html)
  - [PSUBSCRIBE](http://redisdoc.com/pubsub/psubscribe.html)
  - [UNSUBSCRIBE](http://redisdoc.com/pubsub/unsubscribe.html)
  - [PUNSUBSCRIBE](http://redisdoc.com/pubsub/punsubscribe.html)
  - [PUBSUB](http://redisdoc.com/pubsub/pubsub.html)
- 复制
  - [SLAVEOF](http://redisdoc.com/replication/slaveof.html)
  - [ROLE](http://redisdoc.com/replication/role.html)
- 客户端与服务器
  - [AUTH](http://redisdoc.com/client_and_server/auth.html)
  - [QUIT](http://redisdoc.com/client_and_server/quit.html)
  - [INFO](http://redisdoc.com/client_and_server/info.html)
  - [SHUTDOWN](http://redisdoc.com/client_and_server/shutdown.html)
  - [TIME](http://redisdoc.com/client_and_server/time.html)
  - [CLIENT_GETNAME](http://redisdoc.com/client_and_server/client_getname.html)
  - [CLIENT_KILL](http://redisdoc.com/client_and_server/client_kill.html)
  - [CLIENT_LIST](http://redisdoc.com/client_and_server/client_list.html)
  - [CLIENT_SETNAME](http://redisdoc.com/client_and_server/client_setname.html)
- 配置选项
  - [CONFIG_SET](http://redisdoc.com/configure/config_set.html)
  - [CONFIG_GET](http://redisdoc.com/configure/config_get.html)
  - [CONFIG_RESETSTAT](http://redisdoc.com/configure/config_resetstat.html)
  - [CONFIG_REWRITE](http://redisdoc.com/configure/config_rewrite.html)
- 调试
  - [PING](http://redisdoc.com/debug/ping.html)
  - [ECHO](http://redisdoc.com/debug/echo.html)
  - [OBJECT](http://redisdoc.com/debug/object.html)
  - [SLOWLOG](http://redisdoc.com/debug/slowlog.html)
  - [MONITOR](http://redisdoc.com/debug/monitor.html)
  - [DEBUG_OBJECT](http://redisdoc.com/debug/debug_object.html)
  - [DEBUG_SEGFAULT](http://redisdoc.com/debug/debug_segfault.html)
- 内部命令
  - [MIGRATE](http://redisdoc.com/internal/migrate.html)
  - [DUMP](http://redisdoc.com/internal/dump.html)
  - [RESTORE](http://redisdoc.com/internal/restore.html)
  - [SYNC](http://redisdoc.com/internal/sync.html)
  - [PSYNC](http://redisdoc.com/internal/psync.html)
- 功能文档
  - [Redis 集群规范](http://redisdoc.com/topic/cluster-spec.html)
  - [持久化（persistence）](http://redisdoc.com/topic/persistence.html)
  - [发布与订阅（pub/sub）](http://redisdoc.com/topic/pubsub.html)
  - [Sentinel](http://redisdoc.com/topic/sentinel.html)
  - [集群教程](http://redisdoc.com/topic/cluster-tutorial.html)
  - [键空间通知（keyspace notification）](http://redisdoc.com/topic/notification.html)
  - [通信协议（protocol）](http://redisdoc.com/topic/protocol.html)
  - [复制（Replication）](http://redisdoc.com/topic/replication.html)
  - [事务（transaction）](http://redisdoc.com/topic/transaction.html)

redis key集中过期问题，集中过期导致redis压力过大而卡顿

采用一定范围内的随机过期时间

Redis也提供了一些简单的计算功能，比如排序、聚合等，对于这些操作，单线程模型实际会严重影响整体吞吐量，CPU计算过程中，整个IO调度都是被阻塞住的。

**redis分布式锁参考 本博客[多线程进阶篇](<https://muggle.javaboy.org/2019/04/23/thread-3/>)**

## springboot 分布式session

```java
@Configuration  
@EnableRedisHttpSession  
public class RedisSessionConfig {  
}  
```

```xml
<dependency>  
        <groupId>org.springframework.boot</groupId>  
        <artifactId>spring-boot-starter-redis</artifactId>  
</dependency>  
<dependency>  
        <groupId>org.springframework.session</groupId>  
        <artifactId>spring-session-data-redis</artifactId>  
</dependency>
```

```properties
spring.redis.host=localhost  
spring.redis.port=6379  
```

**注意：springboot2.1有包冲突，本配置只适用于2.1以下**

## mybatis的二级缓存

二级缓存是mapper级别的缓存，多个SqlSession去操作同一个Mapper的sql语句，多个SqlSession可以共用二级缓存，二级缓存是跨SqlSession的。

UserMapper有一个二级缓存区域（按namespace分），其它mapper也有自己的二级缓存区域（按namespace分）。每一个namespace的mapper都有一个二级缓存区域，两个mapper的namespace如果相同，这两个mapper执行sql查询到数据将存在相同的二级缓存区域中。sql节点可配置userCache flushcache

打开二级缓存总开关（springboot默认开启），在mapper中使用`<cache/>`打开二级缓存 在分布式系统中不能直接使用二级缓存

`<cache />`的属性：

- eviction：代表的是缓存收回策略，有一下策略：
  1. LRU，  最近最少使用的，移除最长时间不用的对象。
  2. FIFO，先进先出，按对象进入缓存的顺序来移除他们
  3. SOFT， 软引用，移除基于垃圾回收器状态和软引用规则的对象。
  4. WEAK，若引用，更积极的移除基于垃圾收集器状态和若引用规则的对象
- flushInterval：刷新间隔时间，单位为毫秒，默认是当sql执行的时候才回去刷新。
- size：引用数目，一个正整数，代表缓存最多可以存储多少对象，不宜设置过大，过大会造成内存溢出。
- readOnly：只读，意味着缓存数据只能读取，不能修改，这样设置的好处是我们可以快速读取缓存，去诶但是我们没有办法修改缓存。默认值为false，不允许我们修改。



## 分布式缓存

分布式缓存策略

mybatis整合ehcache实现分布式缓存、jetcache、spring cache

jetcache整合笔记：

```xml
        <dependency>
            <groupId>com.alicp.jetcache</groupId>
            <artifactId>jetcache-starter-redis</artifactId>
            <version>2.4.4</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
```

```java
@SpringBootApplication
@EnableMethodCache(basePackages = "com.muggle.jetcahetest")
@EnableCreateCacheAnnotation
public class JetcaheTestApplication {

    public static void main(String[] args) {
        SpringApplication.run(JetcaheTestApplication.class, args);
    }

}
```

```java
public interface Server {

    @Cached(cacheType = CacheType.REMOTE)
    int test (String message);
}
```

```java
@Service
public class ServerImpl implements Server {
    @Override
    public int test(String message) {
        System.out.println(">>>");
        return 666;
    }
}
```

更多文档参考[jetCache github 地址][]

分布式缓存的应用

合并批量更新，提高io

缓存的粒度问题，缓存数据是全量还是部分

### cache cloud 使用

### 分布式缓存原理分析

- 传统分布式算法：HASH算法或者取模算法
- Consistent hashing一致性算法原理
- Hash倾斜性
- 虚拟节点
- Consistent hashing命中率

Consistent hashing 是一致性hash算法

博客：[一致性哈希](<https://blog.csdn.net/qq_35956041/article/details/81026972>)

哈希倾斜：缓存任务分配不均，采用虚拟节点避免

缓存穿透：缓存未起作用

缓存雪崩：缓存雪崩可能是因为数据未加载到缓存中，或者缓存同一时间大面积的失效，从而导致所有请求都去查数据库，导致数据库CPU和内存负载过高，甚至宕机。

缓存的算法

FIFO算法：First in First out，先进先出。原则：一个数据最先进入缓存中，则应该最早淘汰掉。也就是说，当缓存满的时候，应当把最先进入缓存的数据给淘汰掉。
LFU算法：Least Frequently Used，最不经常使用算法。
LRU算法：Least Recently Used，近期最少使用算法。

LRU和LFU的区别。LFU算法是根据在一段时间里数据项被使用的次数选择出最少使用的数据项，即根据使用次数的差异来决定。而LRU是根据使用时间的差异来决定的

## redis运维（抄录自 https://mp.weixin.qq.com/s/TvIxovAi6XfR7RGigtHRtQ）

### 快照持久化

redis中的快照持久化默认是开启的，redis.conf中相关配置主要有如下几项：

```properties
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
dbfilename dump.rdb
dir ./
```

前面三个save相关的选项表示备份的频率，分别表示`900秒内至少一个键被更改则进行快照，300秒内至少10个键被更改则进行快照，60秒内至少10000个键被更改则进行快照，`stop-writes-on-bgsave-error表示在快照创建出错后，是否继续执行写命令，rdbcompression则表示是否对快照文件进行压缩，dbfilename表示生成的快照文件的名字，dir则表示生成的快照文件的位置，在redis中，快照持久化默认就是开启的。

1.在redis运行过程中，我们可以向redis发送一条save命令来创建一个快照，save是一个阻塞命令，redis在接收到save命令之后，开始执行备份操作之后，在备份操作执行完毕之前，将不再处理其他请求，其他请求将被挂起，因此这个命令我们用的不多。save命令执行如下：

```
127.0.0.1:6379> SAVE
OK
```

2.在redis运行过程中，我们也可以发送一条bgsave命令来创建一个快照，不同于save命令，bgsave命令会fork一个子进程，然后这个子进程负责执行将快照写入硬盘，而父进程则继续处理客户端发来的请求，这样就不会导致客户端命令阻塞了。如下：

```
127.0.0.1:6379> BGSAVE
Background saving started
```

3.如果我们在redis.conf中配置了如下选项：

```
save 900 1
save 300 10
save 60 10000
```

那么当条件满足时，比如900秒内有一个key被操作了，那么redis就会自动触发bgsava命令进行备份。我们可以根据实际需求在redis.conf中配置多个这种触发规则。

4.还有一种情况也会触发save命令，那就是我们执行shutdown命令时，当我们用shutdown命令关闭redis时，此时也会执行一个save命令进行备份操作，并在备份操作完成后将服务器关闭。

5.还有一种特殊情况也会触发bgsave命令，就是在主从备份的时候。当从机连接上主机后，会发送一条sync命令来开始一次复制操作，此时主机会开始一次bgsave操作，并在bgsave操作结束后向从机发送快照数据实现数据同步。

### aof持久化

与快照持久化不同，AOF持久化是将被执行的命令写到aof文件末尾，在恢复时只需要从头到尾执行一遍写命令即可恢复数据，AOF在redis中默认也是没有开启的，需要我们手动开启，开启方式如下：

打开redis.conf配置文件，修改appendonly属性值为yes，如下：

```
appendonly yes
```

另外几个和AOF相关的属性如下：

```
appendfilename "appendonly.aof"
# appendfsync always
appendfsync everysec
# appendfsync no
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

这几个属性的含义分别如下：

1.appendfilename表示生成的AOF备份文件的文件名。
2.appendfsync表示备份的时机，always表示每执行一个命令就备份一次，everysec表示每秒备份一次，no表示将备份时机交给操作系统。
3.no-appendfsync-on-rewrite表示在对aof文件进行压缩时，是否执行同步操作。
4.最后两行配置表示AOF文件的压缩时机，这个我们一会再细说。

同时为了避免快照备份的影响，我们将快照备份关闭，关闭方式如下：

```
save ""
# save 900 1
# save 300 10
# save 60 10000
```

此时，当我们在redis中进行数据操作时，就会自动生成AOF的配置文件appendonly.aof

AOF备份的几个关键点

1.通过上面的介绍，小伙伴们了解到appendfsync的取值一共有三种，我们在项目中首选everysec，always选项会严重降低redis性能。
2.使用everysec，最坏的情况下我们可能丢失1秒的数据。

AOF文件的重写与压缩

AOF备份有很多明显的优势，当然也有劣势，那就是文件大小。随着系统的运行，AOF的文件会越来越大，甚至把整个电脑的硬盘填满，AOF文件的重写与压缩机制可以在一定程度上缓解这个问题。
当AOF的备份文件过大时，我们可以向redis发送一条bgrewriteaof命令进行文件重写，如下：

```
127.0.0.1:6379> BGREWRITEAOF
Background append only file rewriting started
(0.71s)
```

bgrewriteaof的执行原理和我们上文说的bgsave的原理一致，这里我就不再赘述，因此bgsave执行过程中存在的问题在这里也一样存在。

bgrewriteaof也可以自动执行，自动执行时间则依赖于auto-aof-rewrite-percentage和auto-aof-rewrite-min-size配置，auto-aof-rewrite-percentage 100表示当目前aof文件大小超过上一次重写时的aof文件大小的百分之多少时会再次进行重写，如果之前没有重写，则以启动时的aof文件大小为依据，同时还要求AOF文件的大小至少要大于64M(auto-aof-rewrite-min-size 64mb)。

### redis主从复制

6379是主机，即master，6380和6381是从机，即slave，那么如何配置这种实例关系呢，很简单，分别在6380和6381上执行如下命令：

```
127.0.0.1:6381> SLAVEOF 127.0.0.1 6379
OK
```

这一步也可以通过在两个从机的redis.conf中添加如下配置来解决：

```
slaveof 127.0.0.1 6379
```

主从复制注意点

1.如果主机已经运行了一段时间了，并且了已经存储了一些数据了，此时从机连上来，那么从机会将主机上所有的数据进行备份，而不是从连接的那个时间点开始备份。
2.配置了主从复制之后，主机上可读可写，但是从机只能读取不能写入（可以通过修改redis.conf中 slave-read-only 的值让从机也可以执行写操作）。
3.在整个主从结构运行过程中，如果主机不幸挂掉，重启之后，他依然是主机，主从复制操作也能够继续进行。

复制原理

每一个master都有一个replication ID，这是一个较大的伪随机字符串，标记了一个给定的数据集。每个master也持有一个偏移量，master将自己产生的复制流发送给slave时，发送多少个字节的数据，自身的偏移量就会增加多少，目的是当有新的操作修改自己的数据集时，它可以以此更新slave的状态。复制偏移量即使在没有一个slave连接到master时，也会自增，所以基本上每一对给定的Replication ID, offset都会标识一个master数据集的确切版本。当slave连接到master时，它们使用PSYNC命令来发送它们记录的旧的master replication ID和它们至今为止处理的偏移量。通过这种方式，master能够仅发送slave所需的增量部分。但是如果master的缓冲区中没有足够的命令积压缓冲记录，或者如果slave引用了不再知道的历史记录（replication ID），则会转而进行一个全量重同步：在这种情况下，slave会得到一个完整的数据集副本，从头开始(参考redis官网)。

简单来说，就是以下几个步骤：

```
    1.slave启动成功连接到master后会发送一个sync命令。  
    2.Master接到命令启动后台的存盘进程，同时收集所有接收到的用于修改数据集命令。  
    3.在后台进程执行完毕之后，master将传送整个数据文件到slave,以完成一次完全同步。  
    4.全量复制：而slave服务在接收到数据库文件数据后，将其存盘并加载到内存中。  
    5.增量复制：Master继续将新的所有收集到的修改命令依次传给slave,完成同步。  
    6.但是只要是重新连接master,一次完全同步（全量复制)将被自动执行。  
```

我们搭建的主从复制模式是下面这样的：

![img](https://mmbiz.qpic.cn/mmbiz_png/GvtDGKK4uYnKsYW7dwk0aaRIrKcESa9ibiaq4WfV2TDDvyGMsfjVVZ3K8oKEYT6m7YfJQekNiayQ4PfknStVl21QQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)  

实际上，一主二仆的主从复制，我们可以搭建成下面这种结构：

![img](https://mmbiz.qpic.cn/mmbiz_png/GvtDGKK4uYnKsYW7dwk0aaRIrKcESa9ibbMvoJzK9ycEft3gcMssde1knu6OlGzgBWlRFRNyZYFuIc3pBUIce7g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)  

哨兵模式，其实并不复杂，我们还是在我们前面的基础上来搭建哨兵模式。假设现在我的master是6379，两个从机分别是6380和6381，两个从机都是从6379上复制数据。先按照上文的步骤，我们配置好一主二仆，然后在redis目录下打开sentinel.conf文件，做如下配置：

```
sentinel monitor mymaster 127.0.0.1 6379 1
```

其中mymaster是给要监控的主机取的名字，随意取，后面是主机地址，最后面的2表示有多少个sentinel认为主机挂掉了，就进行切换（我这里只有一个，因此设置为1）。好了，配置完成后，输入如下命令启动哨兵：

```java
redis-sentinel sentinel.conf
```

6379挂掉之后，redis内部重新举行了选举，6380重新上位。此时，如果6379重启，也不再是扛把子了，只能屈身做一个slave了。

### 集群搭建

Redis集群架构如下图：

![img](https://mmbiz.qpic.cn/mmbiz_png/GvtDGKK4uYmokRcFGBAhCcEXKrK04yXHyTcYLtNXvWCZjjS5Vl9wWsg323VBBmboGhJ6Ovfia4Pqc2oLadKcqvg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)  

Redis集群运行原理如下：

1.所有的Redis节点彼此互联(PING-PONG机制),内部使用二进制协议优化传输速度和带宽
2.节点的fail是通过集群中超过半数的节点检测失效时才生效
3.客户端与Redis节点直连,不需要中间proxy层，客户端不需要连接集群所有节点，连接集群中任何一个可用节点即可
4.Redis-cluster把所有的物理节点映射到[0-16383]slot上,cluster (簇)负责维护`node<->slot<->value`。Redis集群中内置了16384个哈希槽，当需要在Redis集群中放置一个key-value时，Redis先对key使用crc16算法算出一个结果，然后把结果对 16384 求余数，这样每个key都会对应一个编号在 0-16383 之间的哈希槽，Redis 会根据节点数量大致均等的将哈希槽映射到不同的节点



