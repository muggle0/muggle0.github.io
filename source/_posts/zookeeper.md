---
title: zookeeper 浅解
date: 2019-06-15 17:23:46
tags: 中间件
---

从官网 https://apache.org/dist/zookeeper/zookeeper-3.5.5/ 上下载zk(注意windows也是下载 tar.gz后解压)，./conf下有个`zoo_sample.cfg` 复制到同目录下改名为`zoo.cfg`，在目录下新建data和log文件夹，修改zoo.cfg中的 dataDir 和 `dataLogDir `为 data和log的路径。现在启动zk，在bin目录下有个`zkServer.cmd`，运行启动。启动ZK客户端对ZK进行简单的读写操作，在bin目录下打开cmd，运行：

<!--more-->

```cmd
./zkCli.cmd 127.0.0.1:2181
```

## 1 ZK介绍
`zookeeper`是基于观察者模式设计的分布式服务管理框架，它负责存储和管理比较重要的分布式数据并通知观察者数据的变化状态，直白的说zookeeper是一个数据存储加消息通知系统。zookeeper的应用场景有:

- 统一命名服务：在分布式系统中给每个应用配置一个全局唯一名称，并统一管理
- 统一配置管理：将分布式系统一些配置信息放入到ZK中进行管理
- 统一集群管理：管理监听集群状态
- 服务节点动态上下线：实时通知应用分布式系统中有哪些服务节点。

zk的特性：
- 顺序一致性： 从同一客户端发起的事务请求，最终将会严格地按照顺序被应用到 ZooKeeper 中去。
- 原子性： 所有事务请求的处理结果在整个集群中所有机器上的应用情况是一致的，也就是说，要么整个集群中所有的机器都成功应用了某一个事务，要么都没有应用。
- 单一系统映像 ： 无论客户端连到哪一个 ZooKeeper 服务器上，其看到的服务端数据模型都是一致的。
- 可靠性： 一旦一次更改请求被应用，更改的结果就会被持久化，直到被下一次更改覆盖。

## 2 ZNode

zookeeper的数据结构整体上一棵树，每个节点被称作`ZNode`，每个ZNode默认存储1MB的数据，每个ZNode 都可以通过路径唯一标识。ZNode共有四种类型：
- 持久节点：指在节点创建后，就一直存在，直到有删除操作来主动清除这个节点。不会因为客户端会话失效而清除；
- 持久顺序节点：在持久节点基础上增加了有序性，其每创建一个子节点都会自动为给节点名加上一个数字后缀作为新的节点名。

- 临时节点：临时节点的生命周期和客户端会话绑定。也就是说，如果客户端会话失效，那么这个节点就会自动被清除掉。
- 临时顺序节点：在临时节点基础上增加了有序性；参考持久顺序节点。

## 3 ZK指令
在ZK的安装包中有一个ZK客户端，启动ZK客户端可在其中输入相应的指令来操作ZK，下面对这些指令做简单介绍：

| 指令              | 描述                                                         |
| ----------------- | ------------------------------------------------------------ |
| help              | 显示所有操作命令                                             |
| ls path [watch]   | 查看当前节点内容                                             |
| ls2  path [watch] | 查看当前节点数据并能看到更新次数等数据                       |
| create            | 不带参数创建普通持久节点，-s 创建持久顺序节点 -e 创建临时节点，-s -e 创建 临时顺序节点 |
| get path [wathc]  | 获取节点值                                                   |
| set path          | 给节点赋值                                                   |
| stat path         | 查看节点状态                                                 |
| delete path       | 删除节点                                                     |
| rmr               | 递归删除节点 (参考rm-rf）                                    |
操作示例：
```shell
# 连接zk
./zkCli.sh -server master 2181

# 列出 / 下的节点
ls /

# 创建节点
create /zk-test "123"
create  -s   /zk-test  “test123”
create -e /zk-test123 "test1234"

# 删除节点
delete /zk-test

# 获取节点
get /zk-123

#更新节点
set  /zk-123 "d"

```
## 4 ZK配置文件
示例：
```shell

tickTime=2000
dataDir=E:/zookeeper/zookeeper-3.4.8 - colony/zookeeper-1/tmp/zookeeper/
clientPort=2181
initLimit=10
syncLimit=5
server.1=127.0.0.1:2888:3888
server.2=127.0.0.1:2889:3889
server.3=127.0.0.1:2890:3890
```
配置项说明：
简单列举，详细参考 http://www.aboutyun.com/forum.php?mod=viewthread&tid=13909

- clientPort: 客户端连接server的端口，即zk对外服务端口，一般设置为2181。
- dataDir : 把内存中的数据存储成快照文件snapshot的目录
- tickTime: ZK中的一个时间单元
- syncLimit: 如果Leader发出心跳包在syncLimit之后，还没有从Follower那里收到响应，那么就认为这个Follower已经不在线了。


## 5 ZK机制
### 5.1 Zookeeper工作原理
Zab协议 的全称是 Zookeeper Atomic Broadcast （Zookeeper原子广播）。ZAB协议定义了 选举（election）、发现（discovery）、同步（sync）、广播(Broadcast) 四个阶段；
选举阶段就是选举出leader。发现阶段follower节点向准leader推送自己的信息，接受准leader的newEpoch指令，检查newEpoch有效性,如果校验没有问题则正式进入一个新的leader统治时期（epoch）。同步阶段将Follower与Leader的数据进行同步，由Leader发起同步指令，最终保持集群数据的一致性；广播阶段，leader发起广播，Follower开始提交事务。

为了保证事务的顺序一致性，zookeeper采用了递增的事务id号（zxid）来标识事务。所有的提议（proposal）都在被提出的时候加上了zxid。zxid是一个64位的数字，它高32位用来标识leader关系是否改变，每次一个leader被选出来，它都会有一个新的标识，代表当前leader，低32位用于递增计数。
在ZK集群中，Server有三种状态： 
- LOOKING：当前Server不知道leader是谁，正在搜寻
- LEADING：当前Server即为选举出来的leader
- FOLLOWING：leader已经选举出来，当前Server与之同步

当ZK的server挂掉半数以上，leader就认为集群不能再正常工作了；所以ZK集群一般为奇数个。 

### 5.2 ZK选主流程
ZK集群中每个Server启动，首先会投自己一票，然后向外对其他ZK发送报文，如果有响应则互相交换投票结果，如果结果无法确定leader是谁则继续投票。投票规则是优先投票给id最大的server，且不能重复投某个server。因此一个server若想做leader，它的id要足够大（通过配置文件配置），而且还有尽快和其他server建立通讯。


### 5.3 Broadcast(广播)
当客户端提交事务请求时Leader节点为每一个请求生成一个Proposal(提案)，将其发送给集群中所有的Follower节点，收到过半Follower的反馈后开始对事务进行提交；只需要得到过半的Follower节点反馈Ack（同意）就可以对事务进行提交；过半的Follower节点反馈Ack 后，leader发送commit消息同时自身也会完成事务提交，Follower 接收到 commit 消息后，会将事务提交。

Follower必须保证事务的顺序一致性的，也就是说先被发送的Proposal必须先被；消息广播使用了TCP协议进行通讯所有保证了接受和发送事务的顺序性。广播消息时Leader节点为每个Proposal分配一个全局递增的ZXID（事务ID），每个Proposal都按照ZXID顺序来处理。

如果我们连接上某个zk发送一个写请求，如果这个zk不是Leader，那么它会把接受到的请求进一步转发给Leader，然后leader就会执行上面的广播过程。而其他的zk就能同步写数据，保证数据一致。


## 6  ZK面试问题

- 脑裂：由于心跳超时（网络原因导致的）认为master死了，但其实master还存活着（假死），假死会发起新的master选举，选举出一个新的master。但是客户端还能和旧的master通信，导致一部分客户端连接旧master（直连）,一部分客户端连接新的master
- znode类型：临时无序，临时有序，持久无序，持久有序
- Zookeeper通知机制：client端会对某个znode建立一个watcher事件，当该znode发生变化时，这些client会收到zk的通知，然后client可以根据znode变化来做出业务上的改变等。
- 概述zk 工作原理：Zookeeper 的核心是原子广播，这个机制保证了各个Server之间的同步。实现这个机制的协议叫做Zab协议。Zab协议有两种模式，它们分别是恢复模式（选主）和广播模式（同步）。当服务启动或者在领导者崩溃后，Zab就进入了恢复模式，当领导者被选举出来，且大多数Server完成了和 leader的状态同步以后，恢复模式就结束了。状态同步保证了leader和Server具有相同的系统状态。



