---
title: rabbitMQ 结合 springboot 使用 三
date: 2020-12-16
tags: 中间件
---
## `ListenerContainer ` 的使用

在消费端，我们的消费监听器是运行在 监听器容器之中的（ `ListenerContainer` ），springboot 给我们提供了两个监听器容器 `SimpleMessageListenerContainer` 和 `DirectMessageListenerContainer ` 在配置文件中凡是以 `spring.rabbitmq.listener.simple` 开头的就是对第一个容器的配置，以 `spring.rabbitmq.listener.direct` 开头的是对第二个容器的配置。其实这两个容器类让我很费劲；首先官方文档并没有说哪个是默认的容器，似乎两个都能用；其次，它说这个容器默认是单例模式的，但它又提供了工厂方法，而且我们看 `@RabbitListener` 注解源码：
<!--more-->
```java
Target({ElementType.TYPE, ElementType.METHOD, ElementType.ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
@MessageMapping
@Documented
@Repeatable(RabbitListeners.class)
public @interface RabbitListener {
    String id() default "";
    String containerFactory() default "";
    ......
}
```

它是指定一个 `containerFactory` 那我通过 `@Bean` 注解注册一个 `ListenerContainer ` ` 到底有没有用。

保险起见这里教程中建议注册一个`containerFactory`  而不是一个单例的`ListenerContainer `  那我可以对这个容器工厂做哪些设置呢。它的官方文档`<https://docs.spring.io/spring-amqp/docs/2.1.8.RELEASE/api/>` 其中前往提到的序列化问题就可以配置这个工厂bean来解决：

```java
@Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        // 传入一个序列化器 也可以通过 rabbitTemplate.setMessageConverter(）来配置
        factory.setMessageConverter(new MessagingMessageConverter());
        return factory;
    }
```

除此之外 它还能设置事务的长度，消费者并发数，消息重试的相关参数等。小伙伴自己按需查阅资料去进行尝试，这里由于篇幅问题就不做说明了。

## 8. 惰性队列

在 rabbit3.6 版本引入了惰性队列的的概念；默认情况下队列的消息会尽可能的存储在内存之中，这样可以更加快速的将消息发送给消费者，就算持久化的消息也会在内存中做备份。当 rabbit 需要释放内存的时候，会将内存中的消息写入磁盘。这个操作不仅耗时还阻塞队列，让队列无法写入消息。于是 rabbit 将队列分为了两中模式——`default` 模式和 `lazy` 模式来解决这一问题。`lazy` 模式即为惰性队列的模式。惰性队列 通过参数 `x-queue-mode`来配置，代码可参考死信队列，通过  `QueueBuilder` 的 `withArgument` 来指定参数。

惰性队列和普通队列相比，只有很小的内存开销。惰性队列会将消息直接写入到磁盘，需要消费的时候再取出来。当消息量级很大，内存完全不够用的时候，普通队列要经历这样的过程——将消息读到内存 —> 内存满了需要给后面的消息腾地方，将消息写入磁盘—>消费到这条消息，将消息又读入内存。所以当消息量级很大的时候，惰性队列性能要好过普通队列，当内存完全够用的时候则不然。

##  事务

  事务特性是针对生产者投递消息而言的，对我们的项目来说 rabbit 的事务是很重要的；假如没有事务特性，在一个方法中，数据库插入数据失败回滚了，而对应的消息却无法回滚，就会产生一条错误的消息。

rabbit 中的事务机制和 callable 机制是互斥的，也就是说只有 `spring.rabbitmq.template.mandatory=false` 的时候才能使用。rabbit 事务的声明，提交，回滚的方法是channel的 `txSelect()`，`txCoomit()` ，`txRollback()`。但是在 springboot 我们大可不必去手动提交和回滚，可以使用 spring 的声明式事务，上代码：

```java
@Component
@Order(1)
public class RabbitConfig {
    @Autowired
    public RabbitConfig( RabbitTemplate rabbitTemplate,MyConfirmCallback confirmCallback,MyReturnCallback returnCallback){
//        rabbitTemplate.setReturnCallback(returnCallback);
//        rabbitTemplate.setConfirmCallback(confirmCallback);
        // 设置事务环境，使得可以使用RabbitMQ事务
        rabbitTemplate.setChannelTransacted(true);
    }
}
```

生产者：

```java
@Service
public class RabbitTestService {
    @Autowired
    RabbitTemplate template;

    @Transactional(rollbackFor = Exception.class)
    public void test() throws InterruptedException {
        for (int i = 0; i < 30; i++) {

            template.convertAndSend("test for " + i);
            System.out.println(">>>>>" +i);
        }
        Thread.sleep(1000);
        throw new RuntimeException();
        

    }
}
```

通过管理界面和，消费者打印窗口，可确定声明式事务是否配置成功。

## 备胎机

备胎机顾名思义就是替代现任的备胎，“正主” 没了后可以及时上位。在rabbitMQ中，如果生产者发送消息，由于路由错误等原因不能到达指定队列，就会路由到备胎队列消费。这样做可以保证未被路由的消息不会丢失。

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

到这里，你已经学习完了rabbitMQ在springboot中的实战相关技术，下一章节我们将学习rabbitMQ运维相关知识

---

作者：muggle [点我关注作者](https://muggle.javaboy.org/2019/03/20/home/) 

出处：https://muggle-book.gitee.io/

版权：本文版权归作者所有 

转载：欢迎转载，但未经作者同意，必须保留此段声明；必须在文章中给出原文连接；否则必究法律责任