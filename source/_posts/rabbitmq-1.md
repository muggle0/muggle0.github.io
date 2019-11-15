---
title: rabbitmq+springboot 第二篇
date: 2019-08-30 08:25:39
tags: 中间件
---

## 1. 持久化

RabbitMQ通过消息持久化来保证消息的可靠性——为了保证RabbitMQ在退出或者发生异常情况下数据不会丢失，需要将 queue ，exchange 和 Message 都持久化。下面分别介绍它们持久化配置的方式。

对于 queue ，exchange 在创建的时候都会提供一个参数用以设置是否持久化，而如果使用它们对应的建造者而不是new，就能很清晰的看到是怎么指定持久化的：

```java
//  创建 queue 指定为非持久化
    QueueBuilder.nonDurable("xxx").build();
//  指定非持久化
     return QueueBuilder.durable("second-direct-queue").build();
//  durable 为true则是持久化，false非持久化
    ExchangeBuilder.topicExchange("topic").durable(true).build();
```

这里需要注意一个地方，**直接在原队列的基础上添加属性是会报错的，它会告诉你队列已经存在。需要你手动打开管理界面把那个队列删除掉，然后重启项目**。

你如果将 queue 的持久化标识 durable 设置为true ,则代表是一个持久的队列，那么在服务重启之后，也会存在，因为服务会把持久化的 queue 存放在硬盘上，当服务重启的时候，会重新什么之前被持久化的queue；但是里面的消息是否为持久化还需要看消息是否做了持久化设置。exchange 的持久化和 Queue 一样将交换机保存在磁盘，重启后这个交换机还会存在。

<!--more-->

那么消息如何持久化呢？在springboot中需要借助`MessagePostProcessor` 消息加工器对消息进行加工 rabbitMQ 才能知道这个消息是不是要持久化，`MessagePostProcessor`还有其他的很多作用，在后文会介绍。下面看如何进行消息的持久化。
创建`MessagePostProcessor`类：

```JAVA
public class MyMessagePostProcessor implements MessagePostProcessor {
    
    @Override
    public Message postProcessMessage(Message message) throws AmqpException {
        message.getMessageProperties().setDeliveryMode(MessageDeliveryMode.PERSISTENT);
        return message;
    }
}
```

生产者通过`MessagePostProcessor`发送消息：

```java
 @Scheduled(fixedRate = 1000)
    private void sendMessageForDlx() {
        rabbitTemplate.convertAndSend("exchange","routing key","mesage",new MyMessagePostProcessor());
    }
```

消息持久化过程：

> 写入文件前会有一个Buffer,大小为1M,数据在写入文件时，首先会写入到这个Buffer，如果Buffer已满，则会将Buffer写入到文件（未必刷到磁盘）。
> 有个固定的刷盘时间：25ms,也就是不管Buffer满不满，每个25ms，Buffer里的数据及未刷新到磁盘的文件内容必定会刷到磁盘。
> 每次消息写入后，如果没有后续写入请求，则会直接将已写入的消息刷到磁盘：使用Erlang的receive x after 0实现，只要进程的信箱里没有消息，则产生一个timeout消息，而timeout会触发刷盘操作。
> 原文链接：https://blog.csdn.net/u013256816/article/details/60875666

## 2. TTL

RabbitMQ可以对消息和队列设置TTL(消息的过期时间)，消息在队列的生存时间一旦超过设置的TTL值，就称为dead message， 消费者将无法再收到该消息。

### 2.1  在队列上设置消息过期时间

设置队列过期加一个参数 `x-message-ttl` 就可以搞定，同样记得先把原队列在管理界面删除再启动项目，才会创建队列成功。创建持久化队列：

```java
    Queue build = QueueBuilder.durable("queue")
//      消息过期的时间
                .withArgument("x-message-ttl",5000L).build();
```

这种方式设置的过期属性特性是一旦消息过期，就会从队列中抹去（及时性）。

### 2.2 通过`MessagePostProcessor`设置消息过期时间

把原来的 `MyMessagePostProcessor` 代码拿过来加一个参数就行了：

```java
public class MyMessagePostProcessor implements MessagePostProcessor {
    private String expirTime;

    public MyMessagePostProcessor(String expirTime){
        this.expirTime=expirTime;
    }
    @Override
    public Message postProcessMessage(Message message) throws AmqpException {
//        设置过期时间
        message.getMessageProperties().setExpiration(expirTime);
//        设置消息持久化
        message.getMessageProperties().setDeliveryMode(MessageDeliveryMode.PERSISTENT);
        return message;
    }
}
```

这种方式设置的过期时间即使消息过期，也不一定会马上从队列中抹去，它会等轮到这个消息即将投递到消费者之前进行判定。如果过期就丢弃，不再投递给消费者

## 3. 优先级

优先级分为消息优先级和队列优先级，队列优先级高的会先被处理，消息优先级高的会先被消费，队列优先级配置参数为`x-max-priority`,配置方式为：

```java
Queue build = QueueBuilder.durable("queue").withArgument("x-max-priority",10)
```

配置的数字越大，优先级越高默认优先级为0，消息优先级设置也一样。消息的优先级还是通过 `MessagePostProcessor` 来设置：

```java
    @Override
    public Message postProcessMessage(Message message) throws AmqpException {
        message.getMessageProperties().setPriority(5);
        return message;
    }
```

## 4. 死信队列

通过参数`x-dead-letter-exchange`将一个队列设置为死信队列。死信队列的机制是，如果一条消息成为死信 `dead message`，它不是直接丢弃掉，而是在转发到另外一个交换机，由这个交换机来处理这条死信。利用这一机制可达到消息延时的效果——先注册一个没有消费者且设置了过期时间的队列死信队列，投递给这个队列的消息因为没有消费者过一段时间后就会过期成为死信，过期的死信转发到对应的死信交换机里面去分配给其他队列去处理这些消息。上代码：

```java
//  注册死信队列
    @Bean("dlxQueue")
    public Queue dlxQueue(){
//        new Queue("text",true, false, false,new HashMap<>())
//        x-dead-letter-exchange声明了队列里的死信转发到的交换机名称
        Queue build = QueueBuilder.durable("dlx-queue").withArgument("x-dead-letter-exchange", "gc-exchange")
//                dead letter携带的routing-key
                .withArgument("x-dead-letter-routing-key", "dlx-key")
//                消息在过期的时间
                .withArgument("x-message-ttl",5000L).build();
        return build;
    }
//  队列的交换机    
    @Bean("dlxExchange")
    public DirectExchange  dlxExchange(){
//        ExchangeBuilder.topicExchange().durable()
        return new DirectExchange("dlx-exchange");
    }
//  真正处理消息的队列
    @Bean("gcQueue")
    public Queue gcQueue(){
        Queue build = QueueBuilder.durable("gc-queue").build();
        return build;
    }
//  略
    @Bean("dlxExchange")
    public DirectExchange  dlxExchange(){
//        ExchangeBuilder.topicExchange().durable()
        return new DirectExchange("dlx-exchange");
    }

    @Bean("gcExchange")
    public DirectExchange  gcExchange(){
        return new DirectExchange("gc-exchange");
    }

    @Bean
    public Binding bindingGcQueue(@Qualifier("gcQueue") Queue queue,@Qualifier("gcExchange")DirectExchange exchange){
        return BindingBuilder.bind(queue).to(exchange).with("dlx-key");
    }

    @Bean
    public Binding bindingDlxQueue(@Qualifier("dlxQueue") Queue queue,@Qualifier("dlxExchange")DirectExchange exchange){
        return BindingBuilder.bind(queue).to(exchange).with("test-dlx");
    }
```

队列和交换机都注册好了，然后我们分别向 `dlx-queue` 分配一个生产者，向 `gc-queue` 分配一个消费者：

```java
 @Scheduled(fixedRate = 1000)
    private void sendMessageForDlx() {
        rabbitTemplate.convertAndSend("dlx-exchange","test-dlx","test");
    }
    
    @RabbitListener(queues = { "gc-queue"})
    public void gcMessage(String message){
        System.out.println(message);
    }
```

打开管理界面界面你能看到消息的流转过程`dlx-queue`被写入消息，而 `gc-queue` 却没有消息,然后 `dlx-queue` 消息减少而`gc-queue` 消息增多。最终消息在`gc-queue` 被消费。

## 5.  生产者确认机制

假如我们将消息投递给交换机，而交换机路由不到队列该怎么处理呢？在 springboot 中 如果交换机找不到队列默认是直接丢弃，如果我们想保证消息百分百投递该怎么办呢？我们可以这样配置，将 `mandatory` 参数设为 true：

```proper
spring.rabbitmq.template.mandatory=true

```

这个参数的作用是：如果消息路由不到队列中去则退还给生产者。我们也可以通过另外两个参数来设置，效果一样：

```properties
spring.rabbitmq.publisher-returns=true
spring.rabbitmq.publisher-confirms=true
```

开启 `publisher-confirms` 和 `publisher-returns` 这两个参数或者 `mandatory` 参数开启的是 生产者的两个监听器 的回调函数 `ConfirmCallback` 和 `ReturnCallback` 。`ConfirmCallback`是在消息发给交换机时被回调，通过这个回调函数我们能知道发送的消息内容，路由键，交换机名称，是否投递成功等内容；而 `ReturnCallback` 则是在交换机路由不到队列的时候被调用。它通过这个回调函数将你的消息退还给你，让你自行处理。上代码：

```java
@Component
public class MyConfirmCallback implements RabbitTemplate.ConfirmCallback {
    @Override
    public void confirm(CorrelationData correlationData, boolean b, String s) {
        System.out.println("消息唯一标识："+correlationData);
        System.out.println("确认结果："+b);
        System.out.println("失败原因："+s);
    }
}

@Component
public class MyReturnCallback implements RabbitTemplate.ReturnCallback {

    @Override
    public void returnedMessage(Message message, int replyCode, String replyText, String exchange, String routingKey) {
        System.out.println("消息主体 message : "+message);
        System.out.println("消息主体 message : "+replyCode);
        System.out.println("描述："+replyText);
        System.out.println("消息使用的交换器 exchange : "+exchange);
        System.out.println("消息使用的路由键 routing : "+routingKey);
    }

}

@Component
@Order(1)
public class RabbitConfig {
    @Autowired
    public RabbitConfig( RabbitTemplate rabbitTemplate,MyConfirmCallback 		confirmCallback,MyReturnCallback returnCallback){
        rabbitTemplate.setReturnCallback(returnCallback);
        rabbitTemplate.setConfirmCallback(confirmCallback);
    }
}

@Component
@Order(5)
public class ScheduleHandler {
    @Autowired
    private AmqpTemplate rabbitTemplate;

    @Scheduled(fixedRate = 6000)
    private void simpleQueueSchedule() {
        System.out.println("<<<<<<<<<<");
        rabbitTemplate.convertAndSend("null-queue","ni----hao");
    }
}
```

配置好之后我们把消息投递给一个不存在的队列 `null-queue` ，你就会看到两个回调函数依次被触发。通过这个机制，生产者就可以确认消息是否被成功投递。在 rabbit 3.0 版本以前还有一个 `immediate` 参数来保证消息所在队列中有消费者，后来被取消。

## 6. 消费者确认机制

在拉模式下，消费者主动去一条消息，不存在确认问题；而推模式下消费者是被动接收消息的，那么如果消费者不想消费这条消息该怎么办呢，rabbit 提供了消费端确认机制，在 springboot 中消费端确认默认是 `NONE` 自动确认，我们需要设置成手动确认 `manual` 或者根据情况确认 `AUTO` 才能使用这一功能：

```properties
# 这里的配置是指向容器 SimpleMessageListenerContainer和DirectMessageListenerContainer 后文会介绍
# spring.rabbitmq.listener.simple.acknowledge-mode=auto
spring.rabbitmq.listener.direct.acknowledge-mode=auto
```

改造消费者：

```java
    @RabbitListener(queues = { "obj-simple-queue"})
    public void testCallBack(Message msg,Channel channel,@Header(AmqpHeaders.DELIVERY_TAG) long tag){
        try {
            // 做些啥
          if (xxx){
                channel.basicAck(tag,false);
            }else {
                channel.basicNack(tag,false,true);
            }
            
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.out.println(msg);
    }
```

采用消息确认机制后，消费者就有足够的时间处理消息(任务)，不用担心处理消息过程中消费者进程挂掉后消息丢失的问题，因为RabbitMQ会一直持有消息直到消费者显式调用 `basicAck`  为止。如果 `RabbitMQ` 没有收到回执并检测到消费者的 rabbit 连接断开，则  rabbit  会将该消息发送给其他消费者进行处理。一个消费者处理消息时间再长也不会导致该消息被发送给其他消费者，除非它的RabbitMQ连接断开。

在代码中有一个参数 `DELIVERY_TAG` 这个参数是投递的标识；当一个消费者向 rabbit 注册后，会建立起一个 `channel` 当 rabbit 向这个 `channel` 投递消息的时候，会附带一个一个单调递增的正整数 `DELIVERY_TAG`，用于标识这是经过 `channel` 的第几条消息，它的范围仅限于该 `channle`。

下面看一下消费者确认和拒绝消息的方法：

```java
void basicNack(long deliveryTag, boolean multiple, boolean requeue)throws IOException;
void basicReject(long deliveryTag, boolean requeue) throws IOException;
void basicAck(long deliveryTag, boolean multiple) throws IOException;
```

`multiple`：为了减少网络流量，手动确认可以被批处理，当该参数为 true 时，则可以一次性确认 delivery_tag 小于等于传入值的channel中缓存的所有消息。`requeue`：消息被拒绝后是否重新进入队列重发。

当 rabbit 队列拥有多个消费者的时候，**队列收到的消息将以轮训的的方式分发到各个消费者**，每条消息只会发送到订阅列表里的一个消费者。这样的会导致一个问题当前一个消费者迟迟不能确认消息的时候，那么下一个消费者只能等。为了解决这个问题，rabbit中 channel 可持有多个未确认消息。可通过配置来指定channel缓存的未确定消息的个数

```java
spring.rabbitmq.listener.simple.prefetch=3
```



消费者的其他相关配置：

```properties
# 消费者端的重试 这里重试不是重发，而是对channel中的消息无法交给监听方法，或者监听方法抛出异常则进行重试，是发生在消费者内部的
spring.rabbitmq.listener.simple.retry.enabled=true
# 初次尝试的时间间隔
spring.rabbitmq.listener..simple.retry.initial-interval=1000 
# 最大重试次数
spring.rabbitmq.listener.simple.retry.max-attempts=3 
#重试时间间隔。
spring.rabbitmq.listener.simple.retry.max-interval=10000 
# 下次重试时间比上次重试时间的倍数
spring.rabbitmq.listener.simple.retry.multiplier=1.0 
# 重试是无状态的还是有状态的。
spring.rabbitmq.listener.simple.retry.stateless=true 

# 并发的消费者最小数量 这里指某一时刻所有消费者并发数量（但似乎最小值没有意义啊）
spring.rabbitmq.listener.concurrency=10
# 并发的消费者最大数量
spring.rabbitmq.listener.max-concurrency=20
```



## 7. `ListenerContainer ` 的使用

在消费端，我们的消费监听器是运行在 监听器容器之中的（ `ListenerContainer` ），springboot 给我们提供了两个监听器容器 `SimpleMessageListenerContainer` 和 `DirectMessageListenerContainer ` 在配置文件中凡是以 `spring.rabbitmq.listener.simple` 开头的就是对第一个容器的配置，以 `spring.rabbitmq.listener.direct` 开头的是对第二个容器的配置。其实这两个容器类让我很费劲；首先官方文档并没有说哪个是默认的容器，似乎两个都能用；其次，它说这个容器默认是单例模式的，但它又提供了工厂方法，而且我们看 `@RabbitListener` 注解源码：

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

在 rabbit3.6 版本引入了惰性队列的的概念；默认情况下队列的消息会尽可能的存储在内存之中，这样可以更加快速的将消息发送给消费者，就算持久化的消息也会在内存中做备份。当 rabbit 需要释放内存的时候，会将内存中的消息写入磁盘。这个操作不仅耗时还阻塞队列，让队列无法写入消息。于是 rabbit 将队列分为了两中模式——`default` 模式和 `lazy` 模式来解决这一问题。`lazy` 模式即为惰性队列的模式。惰性队列 通过参数 `x-queue-mode`来配置，代码可参考第一篇的第三章节。

惰性队列和普通队列相比，只有很小的内存开销。惰性队列会将消息直接写入到磁盘，需要消费的时候再取出来。当消息量级很大，内存完全不够用的时候，普通队列要经历这样的过程——将消息读到内存 —> 内存满了需要给后面的消息腾地方，将消息写入磁盘—>消费到这条消息，将消息又读入内存。所以当消息量级很大的时候，惰性队列性能要好过普通队列，当内存完全够用的时候则不然。

## 9. 事务

  事务特性是针对生产者投递消息而言的，对我们的项目来说 rabbit 的事务是很重要的；假如没有事务特性，在一个方法中，数据库插入数据失败回滚了，而对应的消息却无法回滚，就会产生一条错误的消息。

rabbit 中的事务机制和 callable 机制是互斥的，也就是说只有 `spring.rabbitmq.template.mandatory=false` 的时候才能使用。rabbit 事务的声明，提交，回滚的方法是channel的 `txSelect()`，`txCoomit()` ，`txRollback()`。但是在 springboot 我们大可不必去手动提交和回滚，可以使用 spring 的声明式事务，上代码：

```java
@Component
@Order(1)
public class RabbitConfig {
    @Autowired
    public RabbitConfig( RabbitTemplate rabbitTemplate,MyConfirmCallback confirmCallback,MyReturnCallback returnCallback){
//        rabbitTemplate.setReturnCallback(returnCallback);
//        rabbitTemplate.setConfirmCallback(confirmCallback);+-96
        
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