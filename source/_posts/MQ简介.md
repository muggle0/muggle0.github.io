---
title: MQ简介
date: 2020-12-12 
tags: 中间件
---


`mq` 就是消息队列（`Message Queue`）。想必大家对队列的数据结构已经很熟悉了，消息队列可以简单理解为：把要传输的数据放在队列中，mq 就是存放和发送消息的这么一个队列中间件。在消息队列中，把数据放到消息队列的角色叫做 `生产者`，从消息队列中消费获取数据的叫做 `消费者`。

那么消息队列有哪些使用场景呢? 六字真言：异步削峰解耦。
<!--more-->
## MQ的异步

异步概念想必大家都熟悉了，就是 a应用（或程序） 将数据传递给b应用（或程序）后，不等待b的响应结果直接做下一步动作，而b并行执行，提高效率。使用mq，就能完美支持异步：a将数据发送到mq，然后自己该干嘛干嘛，b监听mq的消息，来了消息就消费它。这样就做到程序或者应用间的异步。

## mq的削峰

首先我们要知道什么是削峰：削峰的全称应该叫削峰填谷。削峰就是当应用或者程序的请求量过大的时候，将一部分请求延时处理，放到请求量不大时间段去处理它。mq削峰填谷的原理也很简单，mq在应用程序中相当于一个 “蓄水池” 的作用——当 “水流量（请求）” 过大的时候，“蓄水池（mq）” 将 "水" 先存起来。当有能力去消费这些水的时候再去从 “蓄水池” 放水。实际的过程是——请求数据先发到 mq ，应用程序监听mq 并消费消息。当请求量大于消费量的时候，请求积压在mq中存储；当消费量大于请求量的时候，请求就会慢慢被处理完。这听上去就像小学做的游泳池放水排水的数学题。

## mq的解耦

mq解耦性是显而易见的，应用程序直接不直接互相耦合，甚至可以不用知道对方的存在。它想要发出什么样的请求，或者拿什么数据，都是去找mq。mq就像个搬运工一样在这些应用之间搬运数据。

## mq 协议及产品

mq 协议有两种，`jms` 和 `AMQP` 。通常而言提到JMS（`Java MessageService`）实际上是指 `JMS API` 。`JMS` 是由Sun公司早期提出的消息标准，旨在为java应用提供统一的消息操作，包括create、send、receive

等。JMS已经成为 `Java Enterprise Edition` 的一部分。从使用角度看，JMS和JDBC担任差不多的角色，用户都是根据相应的接口可以和实现了 `JMS` 的服务进行通信，进行相关的操作。

JMS角色概念：

- JMS provider：实现了JMS接口的消息中间件，如ActiveMQ

- JMS client：生产或者消费消息的应用

- JMS producer/publisher：JMS消息生产者

- JMS consumer/subscriber ：JMS消息消费者

- JMS message：消息，在各个JMS client传输的对象；

- JMS queue：Provider存放等待被消费的消息的地方

- JMS topic：一种提供多个订阅者消费消息的一种机制；在MQ中常常被提到，topic模式。

 `AMQP（advanced message queuing protocol）` 在2003年时被提出，最早用于解决金融领不同平台之间的消息传递交互问题。AMQP是一种 `binary wire-level protocol`（链接协议）。`AMQP` 不从 API 的层面层对使用规范进行限定，而是直接定义网络交换的数据格式。这意味着实现了amqp协议的消息队列中间件支持跨平台。我们可以使用 Java 的 `AMQP provider` 而 `consumer` 可以是golang 。

在AMQP中，消息路由（`messagerouting`）和JMS存在一些差别，在AMQP中增加了 `Exchange` 和 `binding` 的角色。`producer` 将消息发送给 `Exchange` ，`binding` 决定 `Exchange` 的消息应该发送到那个 `queue`，而consumer直接从queue中消费消息。queue和exchange的bind有consumer来决定。

相对而言，AMQP的消息队列使用的更为广泛。如 `rabbitMQ` , `kafka` , `rocketMQ` 等都是实现AMQP协议的消息队列。接下来我们将会学习 `rabbitMQ` 和 `kafka` 的相关知识。 

---

作者：muggle [点我关注作者](https://muggle.javaboy.org/2019/03/20/home/) 

出处：https://muggle-book.gitee.io/

版权：本文版权归作者所有 

转载：欢迎转载，但未经作者同意，必须保留此段声明；必须在文章中给出原文连接；否则必究法律责任