---
title: kafka系列-安装和使用kafka
date: 2020-12-20
tags: 中间件
---

# kafka 介绍

kafka 是一款基于发布订阅的消息系统，Kafka的最大的特点就是高吞吐量以及可水平扩展，
Kafka擅长处理数据量庞大的业务，例如使用Kafka做日志分析、数据计算等。
<!--more-->
## kafka 概念角色介绍

- Broker：kafka 中 broker概念和rabbitMQ的broker概念类似，一个独立的 Kafka 服务器被称为broker，接收来自生产者的消息，为消息设置偏移量，并提交消息到磁盘保存；
- Topic：Topic为主题，也就是相当于消息系统中的队列(queue)，一个Topic中存在多个Partition；注意，这里区别于 rabbitMQ 的 Topic；
- Partition：Partition为分区，是构成Kafka存储结构的最小单位；
- Group：消费者组，一组消费者构成消费者组
- Message：消息

# kafka 安装及使用
kafka 的运行依赖于 zookeeper，它的安装相对于 rabbitMQ来说比较简单。下面介绍Windows下 kafka的安装及其使用。

kafka是依赖于zookeeper的，所以我们先要安装zookeeper ，当然kafka的二进制包里面，包含了zookeeper 的安装包，我们不需要单独的再去下载ZK的安装包；

 在 kafka 官网下载 二进制的 tgz 压缩包： http://kafka.apache.org/downloads.html，解压后它的 bin/windows下有 zk的启动脚本和kafka的启动脚本，
 zk的配置文件和kafka的配置文件在 config文件夹下，分别对应 zookeeper.properties和server.properties。
 由于本人对zk使用的频率也比较高，因此我是单独安装的zk。

 下面我们对kafka进行配置及启动，配置文件说明：
 ```
 # 对外暴露的服务端口
advertised.listeners=PLAINTEXT://ip:9092
# 机器的标识
broker.id=1
# kafka日志存储的位置
log.dirs=c:xxx
# zk的地址
zookeeper.connect=localhost:2181
 ```

启动脚本： 
 ```bat
.\bin\windows\kafka-server-start.bat .\config\server.properties
 ```

接下来我们做一下简单的测试。

执行脚本
```bat
.\bin\windows\kafka-topics.bat --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
```

该操作创建了一个 名为 test 的 kafka 主题，接下来我们可以在主题中写入消息并消费消息了。

执行脚本
```bat
.\bin\windows\kafka-console-producer.bat --broker-list 127.0.0.1:9092 --topic test 
xxx
xxx
```
该操作创建了一个消息生产者，并发送消息 "xxx"

执行脚本,消费消息：
```bat
kafka-console-consumer.bat --bootstrap-server localhost:9092 --topic test --from-beginning

```
