---
title: kafka事务
date: 2021-01-31 11:31:50
tags: 中间件
---


kafka 的事务是从0.11 版本开始支持的，kafka 的事务是基于 Exactly Once 语义的，它能保证生产或消费消息在跨分区和会话的情况下要么全部成功要么全部失败

### 生产者事务

当生产者投递一条事务性的消息时，会先获取一个 transactionID ，并将Producer 获得的PID 和 transactionID 绑定，当 Producer 重启，Producer
会根据当前事务的 transactionID 获取对应的PID。
kafka 管理事务是通过其组件 Transaction Coordinator 来实现的，这个组件管理每个事务的状态，Producer 可以通过transactionID 从这个组件中获得
对应事务的状态，该组件还会将事务状态持久化到kafka一个内部的 Topic 中。
生产者事务的场景：
一批消息写入 a、b、c 三个分区，如果 ab写入成功而c失败，那么kafka就会根据事务的状态对消息进行回滚，将ab写入的消息剔除掉并通知 Producer 投递消息失败。

### 消费者事务

消费者事务的一致性比较弱，只能够保证消费者消费消息是精准一次的（有且只有一次）。消费者有一个参数 islation.level，这个参数指定的是事务的隔离级别。
它的默认值是 read_uncommitted（未提交读），意思是消费者可以消费未commit的消息。当参数设置为 read_committed，则消费者不能消费到未commit的消息。

### 事务的使用场景

kafka事务主要是为了保证数据的一致性，现列举如下几个场景供读者参考：

- producer发的多条消息组成一个事务，这些消息需要对consumer同时可见或者同时不可见；
- producer可能会给多个topic发送消息，需要保证消息要么全部发送成功要么全部发送失败（操作的原子性）；
- 消费者 消费一个topic，然后做处理再发到另一个topic，这个消费和转发的动作应该在同一事物中；
- 如果下游消费者只有等上游消息事务提交以后才能读到，当吞吐量大的时候就会有问题，因此有了 read committed和read uncommitted两种事务隔离级别