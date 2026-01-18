---
title: redis 数据库结构
date: 2022-05-09 14:15:13
tags: redis
---

## redis数据库结构介绍

在redis源码中数据库的结构由server.h/redisDb表示，
redisDb结构的dict字典保存了数据库中的所有键值对，我们将这个字典称为键空间（key space），redisDb源码：
```
typedef struct redisDb {
    dict *dict;                 /* The keyspace for this DB */
    dict *expires;              /* Timeout of keys with a timeout set */
    dict *blocking_keys;        /* Keys with clients waiting for data (BLPOP)*/
    dict *ready_keys;           /* Blocked keys that received a PUSH */
    dict *watched_keys;         /* WATCHED keys for MULTI/EXEC CAS */
    int id;                     /* Database ID */
    long long avg_ttl;          /* Average TTL, just for stats */
} redisDb;
```
源码中redisDb拥有字典属性`dict`，字典中存储了数据库中的键，为字符串类型的redisObject。这个redisObject中的ptr属性指向值的redisObject，结构示意图：
![](images/2022-05-09-15-10-52.png)

## 键空间的维护

当使用Redis命令对数据库进行读写时，服务器不仅会对键空间执行指定的读写操作，还会执行一些额外的维护操作：

1. 在读取一个键之后（读操作和写操作都要对键进行读取），服务器会根据键是否存在来更新服务器的键空间命中（hit）次数或键空间不命中（miss）次数，这两个值可以在INFO stats命令的keyspace_hits属性和keyspace_misses属性中查看。
2. 在读取一个键之后，服务器会更新键的LRU值，关于这个值我们在上一章节已经介绍过了；
3. 如果有客户端使用WATCH命令监视了某个键，那么服务器在对被监视的键进行修改之后，会将这个键标记为脏（dirty），从而让事务程序注意到这个键已经被修改过
4. 如果服务器开启了数据库通知功能，那么在对键进行修改之后，服务器将按配置发送相应的数据库通知

## 键的过期时间

通过EXPIRE命令或者PEXPIRE命令可以设置键的过期时间，那么在数据库中这个过期时间是怎么维护的呢？redisDb结构体中有一个字典属性`expires`便是用来保存键的过期时间的，
我们称这个字典为过期字典。过期字典的键是一个指针，指向键空间中的键；过期字典的值是一个long类型的数，记录了过期时间的时间戳。当客户端执行PEXPIREAT命令，服务器会在数据库的过期字典中关联给定的数据库键和过期时间。

如果现在给key设置一个过期时间，在过期时间到的时候，Redis是如何清除这个key的呢？Redis 中提供了三种过期删除的策略:
- 定时删除：在设置某个 key 的过期时间同时，我们创建一个定时器，让定时器在该过期时间到来时，立即执行对其进行删除的操作；
- 惰性删除：当一个键值对过期的时候，只有再次用到这个键值对的时候才去检查删除这个键值对；
- 定期删除：采样一定个数的key 判断过期比例，并删除过期键，当过期比例不达标则重新采样删除，直到达标。

Redis 中实际采用的策略是惰性删除加定期删除的组合方式，服务器会定期清除掉一部分过期的key，对于那些未清除到的过期key，会在获取这个key的时候进行判断是否过期，过期则删除。
惰性删除会带来一个问题就是当从从库获取一个过期key的时候从库是否应该删除这个key呢？如果一个主库创建的过期键值对，已经过期了，主库在进行定期删除的时候，没有及时的删除掉，这时候从库请求了这个键值对，当执行惰性删除的时候，因为是主库创建的键值对，这时候是不能在从库中删除的。从库会通过惰性删除来判断键值对的是否过期，如果过期则读不到这个键，真正的删除是当主节点触发键过期时，主节点会同步一个del命令给所有的从节点。

我们知道redis 持久化策略中包括RDB持久化功能、AOF持久化，这两种持久化对过期未删除的键处理也是有区别的。RDB持久话不会保存过期未删除的键，而AOF持久化当过期键被惰性删除或者定期删除之后，程序会向AOF文件追加一条DEL命令，来显式地记录该键已被删除。

## 阻塞
在 Redis 命令中，有一些命令是阻塞模式的，BRPOP,  BLPOP, BRPOPLPUSH, 这些命令都有可能造成客户端的阻塞。比如向客户端发来一个blpop key命令，redis先找到对应的key的list，如果list不为空则pop一个数据返回给客户端；如果对应的list不存在或者里面没有数据，就将该key添加到redisDb 的blockling_keys的字典中，value就是想订阅该key的client链表。并将对应的客户端标记为阻塞。
如果客户端发来一个repush key value命令，先从redisDb的blocking_keys中查找是否存在对应的key，如果存在就往redisDb的ready_keys这个链表中添加该key；同时将value插入到对应的list中，并响应客户端。redis处理完客户端命令后都会遍历ready_keys和blockling_keys来筛选出需要pop出的clinet。因此，redis客户端的阻塞是通过ready_keys和blockling_keys联合来实现的，blockling_keys 记录阻塞中的key和客户端，ready_keys记录数据已准备好的key。



