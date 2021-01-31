---
title: rabbitMQ简介
date: 2020-12-13
tags: 中间件
---

前文我们学习了 MQ的相关知识，现在我们来学习一下实现了AMQP协议的 `rabbitMQ` 中间件。rabbitMQ 是使用 erlang 语言编写的中间件（erlang之父 19年4月去世的，很伟大一个程序员）。
<!--more-->
## rabbitMQ 的结构和的角色

学习rabbtMQ我们先要弄清楚这几个概念：`exchange`,`queue`,`routing-key`,`binding-key`,`message`,`publisher`,`exchange`,`binding-key`,`Connection`,`Channel`,`consumer`,`broker`；下面对这些角色概念进行介绍。

消息的发送方被称作`publisher`（生产者），而消息的接收方被称作`consumer`(消费者)，而消息队列服务器实体就是`broker`（指`rabbitMQ`）；消费者或者生产者对rabbitMQ的一个连接被称作`Connection`（连接）,在rabbit的连接模型中，为了提高连接传输效率，采用了`Channel`（管道）这种方式实现多路复用，类似于Nio中的模型；我们知道建立一个TCP连接代价很大，因此TCP连接建立后最好不要断开`Connection`-`Channel`连接模型就是为了达到这种目的；一个消费者（生产者）使用一个`channel`消费（发送）消息，而多个`Channel`共用一个`Connection`。

一个生产者向rabbit投递消息，然后消费者消费这个消息的过程是这样的——生产者将消息投递给rabbit，在rabbit中`exchange`（交换机）首先会接收到这个消息，交换机相当于一个“分拣员”的角色，负责分拣消息，将这些消息存储到和自己绑定的`queue`（队列）中去，然后和队列绑定的消费者会消费这些消息。队列和交换机绑定通过一个`binding-key`（绑定键）来标记，而生产者投递消息给交换机的时候会指定一个`routing-key`（路由键），而交换机会根据路由和绑定键来判断将消息放到那些队列中去（扩展：kafka的数据是存储在 exchange 中，它的 queue 只是逻辑队列）。
图一是rabbitMQ的一个概念简图：
![rabbitMQ概念简图](https://raw.githubusercontent.com/muggle0/muggle0.github.io/master/rabbitmq架构.jpg)
																	图一：rabbitMQ 概念简图

## rabbitMQ交换机类型

在rabbit中交换机共有四种类型，下面对其类型和其消息路由规则做说明：

- `direct exchange`(直连交换机)：消息中的`routing-key`如果和`binding-key`一致， 交换器就将消息发到对应的队列中,`routing-key`要与`binding-key`完全匹配。
- `fanout exchange`(扇型交换机):扇型交换机会将交给自己的消息发到所有和自己绑定的队列中去，它不会去匹配`routing-key`和`binding-key`。
- `topic exchange`(主题交换机):主题交换机的`routing-key`匹配`binding-key`的方式支持模糊匹配， 以.分割单词，`*`匹配一个单词，`#`匹配多个单词，比如如路由键是`com.muggle.first` 能被`com.#`和`*.muggle.*`绑定键匹配。
- `headers exchange`(头交换机):类似主题交换机，但是头交换机使用多个消息属性来代替路由键建立路由规则。通过判断消息头的值能否与指定的绑定相匹配来确立路由规则。当交换机的`x-match`属性为`any`时，消息头的任意一个值被匹配就可以满足条件,当为`all`的时候，就需要消息头的所有值都匹配成功,这种交换机在实际生产中用的并不多。

在实际生产中，我们可以选择不同交换机类型来灵活的配置我们的生产者和消费者之间消息的消费关系。如延时队列，消息广播等的功能。

---

作者：muggle [点我关注作者](https://muggle.javaboy.org/2019/03/20/home/) 

出处：https://muggle-book.gitee.io/

版权：本文版权归作者所有 

转载：欢迎转载，但未经作者同意，必须保留此段声明；必须在文章中给出原文连接；否则必究法律责任