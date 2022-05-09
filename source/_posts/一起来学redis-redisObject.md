---
title: 一起来学redis-redisObject
date: 2022-05-09 10:00:27
tags: redis
---

前文我们看过`redisObject`的源码：
```
typedef struct redisObject {
    unsigned type:4;
    unsigned encoding:4;
    unsigned lru:LRU_BITS; /* LRU time (relative to global lru_clock) or
                            * LFU data (least significant 8 bits frequency
                            * and most significant 16 bits access time). */
    int refcount;
    void *ptr;
} robj;
```

## TYPE与命令多态

我们知道redis的键和值都是以redisObject的形式保存的，而键总是一个字符串对象，而值则可以是字符串对象、列表对象、哈希对象、集合对象或者有序集合对象的其中一种。我们执行`TYPE`指令可以查看键对应的值的属性：
```
redis>TYPE test
hash
```
这个指令就是查看redisObject中的type属性类型，前文我们也提到过对象的类型包括string，list，hash，set,zset。
我们知道del、expire、remane、type等命令是可以使用在各种类型的redisObject上的，而类似lpush、llen等指令就只能用在对应的type上，比如对string类型的redisObject使用llen 结果将会这样：
```
redis>llen test
"WRONGTYPE Operation against a key holding the wrong kind of value"
```
为了确保只有指定类型的键可以执行某些特定的命令，在执行一个类型特定的命令之前，Redis会先检查输入键的类型是否正确，然后再决定是否执行给定的命令。
在执行一个类型特定命令之前，服务器会先检查输入数据库键的值对象的type属性是否为执行命令所需的类型，如果是的话服务器就对键执行指定的命令，否则就抛出警告。

## refcount

为了实现类似jvm的内存回收机制，Redis在自己的对象中添加了一个引用计数属性--refcount，通过这个值程序可以在适当的时候自动释放对象并进行内存回收。
对象的引用计数值随着redisObject生命周期的变化：
- 在创建一个新对象时，引用计数的值会被初始化为1；
- 当对象被一个新程序使用时，它的引用计数值会被增一；
- 当对象不再被一个程序使用时，它的引用计数值会被减一；
- 当对象的引用计数值变为0时，对象所占用的内存会被释放。

对象的整个生命周期可以划分为创建对象、操作对象、释放对象三个阶段。

除了用于实现引用计数内存回收机制之外，对象的引用计数属性还带有对象共享的作用。
假如 A键存储一个"1000"的整数值字符串对象，同时B键也存储了一个"1000"的整数值字符串对象，此时reids只会创建一个"1000"的整数值字符串对象，而它的引用计数会增一。
也就是说到多个key之间可以共享一个对象的时候，只会创建一个对象，而引用计数会相应的增一，另外这种优化只针对整数值字符串对象。目前来说，Redis会在初始化服务器时，创建一万个字符串对象，这些对象包含了从0到9999的所有整数值，当服务器需要用到值为0到9999的字符串对象时，服务器就会使用这些共享对象，而不是新创建对象。`object refcount`指令是可以查看对象的引用数的，下面我们来做一个实验验证：
```
local:0>set a1 100
"OK"

local:0>object refcount a1
"2"

local:0>set a2 100
"OK"

local:0>object refcount a1
"3"
```

第一次set a1 时查看引用计数是2，引用这个值对象的两个程序分别是持有这个值对象的服务器程序，以及共享这个值对象的键a1。
第二次set a2 同样的值发现对象的引用计数变成了3，和我们的理论是一致的。然后我们验证一下字符串：
```
local:0>set b1 xxxx
"OK"

local:0>object refcount b1
"1"

local:0>set b2 xxxx
"OK"

local:0>object refcount b2
"1"

```
我们发现字符串类型之间不存在对象共享，因为字符串的对象共享的验证计算成本比较高，redis出于性能考虑不对字符串类型的对象进行共享。

## lru

redisObject的lru属性，该属性记录了对象最后一次被命令程序访问的时间。查看这个属性的指令为`object idletime`，这个命令在访问键的值对象时，不会修改值对象的lru属性：
```
local:0>object idletime b1
"556"

local:0>object idletime b1
"568"
```
如果redis服务器打开了maxmemory选项，并且服务器用于回收内存的算法为volatile-lru或者allkeys-lru，那么当服务器占用的内存数超过了maxmemory选项所设置的上限值时，空转时长较高的那部分键会优先被服务器释放，从而回收内存。db.c 中有一个 lookupKey 方法：
```
/* Low level key lookup API, not actually called directly from commands
 * implementations that should instead rely on lookupKeyRead(),
 * lookupKeyWrite() and lookupKeyReadWithFlags(). */
robj *lookupKey(redisDb *db, robj *key, int flags) {
    dictEntry *de = dictFind(db->dict,key->ptr);
    if (de) {
        robj *val = dictGetVal(de);

        /* Update the access time for the ageing algorithm.
         * Don't do it if we have a saving child, as this will trigger
         * a copy on write madness. */
        if (server.rdb_child_pid == -1 &&
            server.aof_child_pid == -1 &&
            !(flags & LOOKUP_NOTOUCH))
        {
            if (server.maxmemory_policy & MAXMEMORY_FLAG_LFU) {
                updateLFU(val);
            } else {
                val->lru = LRU_CLOCK();
            }
        }
        return val;
    } else {
        return NULL;
    }
}
```
每次按key获取一个值的时候，都会调用lookupKey函数,如果配置使用了lru模式,该函数会更新value中的lru字段为当前秒级别的时间戳。虽然记录了redisObject的时间戳，但淘汰键时肯定不能遍历比较这个lru值，
这样做计算量太大。实际上redis是这样干的：

1. 随机选取N个key，放入一个pool中(pool的大小为16),pool中的key是按lru大小顺序排列的。
2. 接下来每次随机选取的keylru值必须小于pool中最小的lru才会继续放入，直到将pool放满。
3. 放满之后，每次如果有新的key需要放入，需要将pool中lru最大的一个key取出。
4. 淘汰的时候，直接从pool中选取一个lru最小的值然后将其淘汰。

实际上redis 淘汰策略还有一个lfu算法，该算法采用的是通过记录key的访问次数来选择需要淘汰的key，感兴趣的小伙伴可以百度相关资料。

