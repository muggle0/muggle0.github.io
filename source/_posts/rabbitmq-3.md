---
title: rabbitmq-3
date: 2020-09-07 16:17:20
tags: 中间件
---

## 备胎机

备胎机顾名思义就是替代现任的备胎，“正主” 没了后可以及时上位。在rabbitMQ中，如果生产者发送消息，由于路由错误等原因不能到达指定队列，就会路由到备胎队列消费。这样做可以保证未被路由的消息不会丢失。

<!--more-->

备胎交换机的参数为 `alternate-exchange`来指定做谁的备胎：

```java
   @Bean
    public DirectExchange alternateExchange() {
        Map<String, Object> arguments = new HashMap<>();
        //指定做哪个交换机的备胎
        arguments.put("alternate-exchange", "exchange-boss");
        return new DirectExchange("xxxqueue", true, false, arguments);
    }
    @Bean
    public FanoutExchange bossExchange() {
        // 执行业务的交换机
        return new FanoutExchange("exchange-boss");
    }

```

## rabbitMQ集群

单台 RabbitMQ 服务器可以满足每秒 1000 条消息的吞吐量，如果对吞吐量要求更高就需要构建rabbitMQ集群了。RabbitMQ 集群允许消费者和生产者在 RabbitMQ 单个节点崩惯的情况下继续运行，它可以 通过添加更多的节点来线性地扩展消息通信的吞吐量。当失去一个 RabbitMQ 节点时，客户端 能够重新连接到集群中的任何其他节点并继续生产或者消费。

RabbitMQ 集群不能保证消息的万无一失。即使将消息、队列、交换器等都设置为可持久化，生产端和消费端都正确地使用了确认方式，当集群中一个 RabbitMQ 节点崩溃时，该节 点上的所有队列中的消息也会丢失。 RabbitMQ 集群中的所有节点都会备份所有的元数据信息， 包括队列的名称及属性，交换器的名称及属性，交换器与队列或者交换器与交换器之间的绑定关系， 但是不会备份消息（可以通过镜像队列来解决这个问题）。

rabbitmq可以通过三种方式来部署分布式集群系统，分别是：cluster、federation、shovel。

cluster的特点为:

- 不支持夸网段，用于同一个网段内的局域网
- 可以随意动态的增加和减少
- 节点之间需要运行相同版本的rabbitmq和erlang

federation特点为:

- 需要配置联邦交换机和联邦队列
- 应用于广域网，允许单台服务器上的交换机或队列接收发布到另一台服务器交换机或队列的消息
- 消息会在联盟队列之间转发任意次，直到被消费者接受。

shovel:连接方式与federation的连接方式类似，相当于建立一个消费者，来将消息从一个队列转移到另一个队列。

## 常用命令

```
#开启WEB后台监控
./rabbitmq-plugins enable rabbitmq_management
#启停服务
service rabbitmq-server start
service rabbitmq-server stop
service rabbitmq-server restart
#查看状态
service rabbitmq-server status
#运行节点
rabbitmq-server -detached
# rabbitmqctl（命令行工具）
rabbitmqctl stop_app
rabbitmqctl start_app
#初始化node状态，会从集群中删除该节点
rabbitmqctl reset
#无条件的初始化node状态
rabbitmqctl force_reset
#[--ram]不写则默认为disc
rabbitmqctl join_cluster <clusternode> [--ram]
rabbitmqctl cluster_status

```

