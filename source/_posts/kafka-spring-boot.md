---
title: kafka+spring boot
date: 2021-03-28 10:55:32
tags: 中间件
---
前文介绍了 kafka 的相关特性和原理，这一节我们将学习怎么在springboot中使用kafka；

首先导入依赖

```xml
<dependency>
   <groupId>org.springframework.kafka</groupId>
   <artifactId>spring-kafka</artifactId>
</dependency>
```

<!--more-->

然后启动项添加注解 `@EnableScheduling`，`@EnableKafka` 。第一个注解是用来添加springboot定时任务以方便测试，第二个注解是装配kafka 配置。

接下来我们要在 application 的配置文件：

```properties
## 生产者配置
spring.kafka.consumer.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=test-consumer-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.key-deserializer=org.apache.kafka.common.serialization.StringDeserializer
spring.kafka.consumer.value-deserializer=org.apache.kafka.common.serialization.StringDeserializer

## 消费者配置
spring.kafka.producer.bootstrap-servers=localhost:9092
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer

#消费监听接口监听的主题不存在时，默认会报错
spring.kafka.listener.missing-topics-fatal=false

```

注册一个 `AdminClient` :

```java
 @Bean
    public AdminClient init( KafkaProperties kafkaProperties){
        return KafkaAdminClient.create(kafkaProperties.buildAdminProperties());
    }
```

这里因为是demo，我就将生产者和消费者写在一个程序里面了。

先测试一个简单的收发消息：

```java
@RestController
public class TestController {
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    

    @Autowired
    private   AdminClient adminClient;
    
    @Scheduled(cron = "*/15 * * * * ?")
    public void send() {
        kafkaTemplate.send("xxxxx", "test");
    }
    
    @KafkaListener(topics = "xxxxx",groupId = "test-consumer-group")
    public void listen(ConsumerRecord<?, String> record) throws ExecutionException, InterruptedException {
        String value = record.value();
        System.out.println(value);
    }

}
```

这里我调用了`kafkaTemplate.send` 方法发送消息,第一个参数是消息的主题,第二个参数是消息.
这里我并没有先创建主题,直接往主题里面发消息了,框架会给你直接创建一个默认的主题.
我们也可以直接创建一个主题:

```java
 @Bean
    public NewTopic topic() {
        return new NewTopic("topic-test", 1, (short) 1);
    }
```
当然像 rabbitMQ 的api 那样,spring boot 还非常贴心的准备了 topic 建造者类:

```java
@Bean
public NewTopic topic1() {
    return TopicBuilder.name("thing1")
            .partitions(10)
            .replicas(3)
            .compact()
            .build();
}
```

还可以通过 AdminClient 创建主题：
```java
    @Autowired
    private   AdminClient adminClient;

    public String createTopic(){
        Collection<NewTopic> newTopics = new ArrayList<>(1);
        newTopics.add(new NewTopic("topic-a",1,(short) 1));
        adminClient.createTopics(newTopics);
        System.out.println("》》》》》》》》》》》》》》》 创建topic");
        ListTopicsResult listTopicsResult = adminClient.listTopics();
        System.out.println(">>>>>>>>>>>>>>>>>>>获取列表");
        return "success";
    }
```
第一个参数是主题名称,第二个参数是分区数,第三个分区是副本数(包括leader).

我们可以通过 `AdminClient` 查看 主题信息:

```java
    public String getTopic() throws ExecutionException, InterruptedException {
        ListTopicsResult listTopicsResult = adminClient.listTopics();
        Collection<TopicListing> topicListings = listTopicsResult.listings().get();
        System.out.println(">>>>>>>>>>>>>>>>>>>获取列表");
        return "success";
    }
```

`ListTopicsResult` 的方法返回值都是 `Future` 类型的,这意味这它是异步的,使用的时候需要注意这一点.

和rabbitMQ 类似,kafka 给我们准备了一个默认主题:

```java
    @Scheduled(cron = "*/15 * * * * ?")
    public void sendDefault() {
        kafkaTemplate.sendDefault("xxx");
    }

```
这条消息会被发送到名为 `topic.quick.default` 的主题当中去.
我们要注意 `kafkaTemplate.send` 它的返回值是`ListenableFuture`,从名字我们就能知道它实际上是一个异步的方法,
我们可以通过 `ListenableFuture.addCallback` 方法去指定回调函数:

```java

   @Scheduled(cron = "*/15 * * * * ?")
    public void send() {
        ListenableFuture<SendResult<String, String>> send = kafkaTemplate.send("xxxxx", "test");
        send.addCallback(new ListenableFutureCallback(){
            @Override
            public void onSuccess(Object o) {

            }
            @Override
            public void onFailure(Throwable throwable) {
                
            }
        });
    }
```

我们也可以通过 `ListenableFuture.get` 方法让它阻塞:

```java
    //    @Scheduled(cron = "*/15 * * * * ?")
    public void send1() {
        try {
            kafkaTemplate.send("xxxxx", "test").get(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        }
    }
```


## kafka 事务消息

Spring-kafka自动注册的KafkaTemplate实例是不具有事务消息发送能力的。需要配置属性：


```shell script
spring.kafka.producer.acks=-1
spring.kafka.producer.transaction-id-prefix=kafka_tx
```


当激活事务时 kafkaTemplate 就只能发送事务消息了，发送非事务的消息会报异常。
发送事务消息的方法有两种，一种是通过 kafkaTemplate.executeInTransaction 实现，一种是通过 spring的注解 `@Transactional`
 来实现，代码示例：

```java
    @Scheduled(cron = "*/15 * * * * ?")
    public void sendTrans() {
      kafkaTemplate.executeInTransaction(t ->{
          t.send("xxxxx","test1");
          t.send("xxxxx","test2");
          return true;
      }
          );
    }

    @Scheduled(cron = "*/15 * * * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void sendFoo() {
        kafkaTemplate.send("topic_input", "test");
    
    }

```

## 消费者Ack

消费者消息消息可以自动确认，也可以通过手动确认，开启手动首先需要关闭自动提交，然后设置下consumer的消费模式：

```properties
spring.kafka.consumer.enable-auto-commit=false
spring.kafka.listener.ack-mode=manual
```

配置完成之后我们需要对消费者监听器做一点小改动：

```java
    @KafkaListener( topics = "topic_input")
    public void listen(ConsumerRecord<?, String> record, Acknowledgment ack) {
        System.out.println(record.value());
        ack.acknowledge();
    }
```
如你所见，我们可以通过 `Acknowledgment.acknowledge()` 来手动的确认消息的消费，不确认就不算消费成功，监听器会再次收到这个消息。
对于某些业务场景这个功能还是很必要的，比如消费消息的同时导致写库异常，数据库回滚，那么消息也不应该被ack。

## 消费者监听器生命周期控制
消费者监听器有三个生命周期：启动、停止、继续；如果我们想控制消费者监听器生命周期，需要修改` @KafkaListener` 的 `autoStartup` 属性为false，
并给监听器 id 属性赋值
然后通过`KafkaListenerEndpointRegistry` 控制id 对应的监听器的启动停止继续：

```java
import org.springframework.stereotype.Service;
@Service
public class test {
    @Autowired
    KafkaListenerEndpointRegistry listenerRegistry;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Scheduled(cron = "*/15 * * * * ?")
    @Transactional
    public void testListener(){
        if (i==20){
            listenerRegistry.getListenerContainer("listener1").start();
        }
        System.out.println("生产者生产消息"+i++);
        kafkaTemplate.send("test","xxx"+i);
    }
    
     @KafkaListener( id = "listener1",topics = "test",autoStartup ="false" )
    public void testStart(ConsumerRecord<?, String> record){
        System.out.println(record.value());
    }


}
```

通过观察窗口输出就能看到，生产者生产了20条数据后消费者监听器才开始启动消费。

## 消息转发
kafka 消费者可以将消费到的消息转发到指定的主题中去，比如一条消息需要经过多次流转加工才能走完整个业务流程，需要多个consumer来配合完成。
转发代码示例如下：

```java

    @KafkaListener(topics = "send-a")
    @SendTo("send-b")
    public String sendTest0(ConsumerRecord<?, String> record){
        System.out.println(record.value());
        return "转发消息"+record.value();
    }
    
    @KafkaListener(topics = "send-b")
    public void sendTest1(ConsumerRecord<?, String> record){
        System.out.println(record.value());
    }
    
    @Scheduled(cron = "*/15 * * * * ?")
    @Transactional
    public void producerTest(){
        kafkaTemplate.send("send-a","xxxxxxxxxxxxxx");
    }

```

## 生产者获取消费者响应
结合 `@sendTo注解` 和 `ReplyingKafkaTemplate` 类 生产者可以获取消费者消费消息的结果;
因为 ReplyingKafkaTemplate 是kafkaTemplate 的一个子类，当你往spring 容器注册 这个bean,
kafkaTemplate 的自动装配就会关闭，但是kafkaTemplate 是必须的，因此你需要把这两个bean 都手动注册上。 
配置示例：

```java 

@Configuration
public class KafkaConfig {

    @Bean
    public NewTopic topic2() {
        return new NewTopic("topic-kl", 1, (short) 1);
    }



    @Bean
    public AdminClient init( KafkaProperties kafkaProperties){
        return KafkaAdminClient.create(kafkaProperties.buildAdminProperties());
    }
    
    /**
     * 同步的kafka需要ReplyingKafkaTemplate,指定repliesContainer
     *
     * @param producerFactory
     * @param repliesContainer
     * @return
     */
    @Bean
    public ReplyingKafkaTemplate<String, String, String> replyingTemplate(
        ProducerFactory<String, String> producerFactory,
        ConcurrentMessageListenerContainer<String, String> repliesContainer) {
        ReplyingKafkaTemplate template = new ReplyingKafkaTemplate<>(producerFactory, repliesContainer);
        //同步相应超时时间：10s
        template.setReplyTimeout(10000);
        return template;
    }
    
    @Bean
    public ProducerFactory<String,String> producerFactory(KafkaProperties properties) {
        DefaultKafkaProducerFactory<String, String> producerFactory = new DefaultKafkaProducerFactory<>(properties.buildProducerProperties());
        producerFactory.setTransactionIdPrefix(properties.getProducer().getTransactionIdPrefix());
        return  producerFactory;
//        return new DefaultKafkaProducerFactory<>(properties.producerConfigs(properties));
    }

    public Map<String, Object> producerConfigs(KafkaProperties properties) {
        Map<String, Object> props = new HashMap<>();
        //用于建立与kafka集群的连接，这个list仅仅影响用于初始化的hosts，来发现全部的servers。 格式：host1:port1,host2:port2,…，
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG,String.join(",",properties.getBootstrapServers()));
        // 重试次数
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        // Producer可以将发往同一个Partition的数据做成一个Produce Request发送请求以减少请求次数，该值即为每次批处理的大小,若将该值设为0，则不会进行批处理
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        // Producer可以用来缓存数据的内存大小。该值实际为RecordAccumulator类中的BufferPool，即Producer所管理的最大内存。
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
        //发送一次message最大大小，默认是1M
        //props.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, 20971520);
        // 序列化器
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return props;
    }
    
    /**
     * 指定consumer返回数据到指定的topic
     * @return
     */
    @Bean
    public ConcurrentMessageListenerContainer<String, String>
    repliesContainer(ConcurrentKafkaListenerContainerFactory<String, String> containerFactory) {
        ConcurrentMessageListenerContainer<String, String> repliesContainer =
            containerFactory.createContainer("topic-return");
        repliesContainer.setAutoStartup(true);
        return repliesContainer;
    }
    
    @Bean
//    @ConditionalOnMissingBean(KafkaTemplate.class)
    public KafkaTemplate<?, ?> kafkaTemplate(ProducerFactory<String, String> kafkaProducerFactory,
                                             ObjectProvider<RecordMessageConverter> messageConverter,KafkaProperties properties) {
        KafkaTemplate<String, String> kafkaTemplate = new KafkaTemplate<>(kafkaProducerFactory);
        messageConverter.ifUnique(kafkaTemplate::setMessageConverter);
        kafkaTemplate.setProducerListener( new LoggingProducerListener<>());
        kafkaTemplate.setDefaultTopic(properties.getTemplate().getDefaultTopic());
        return kafkaTemplate;
    }


}
```

生产者接收消费者返回值（这俩最好不要开到一个应用中，否则会很容易生产者超时，观察不到返回的结果）：

```java

    @Scheduled(cron = "*/1 * * * * ?")
    @Transactional
    public void returnTestProducer(){
        ProducerRecord<String, String> record = new ProducerRecord<>("topic-return", "test-return");
        RequestReplyFuture<String, String, String> replyFuture = replyingTemplate.sendAndReceive(record);
        try {
            String value = replyFuture.get().value();
            System.out.println(value);
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }
    }
    
    @KafkaListener(topics = "topic-return")
    @SendTo
    public String listen(String message) {
        return "consumer return:".concat(message);
    }


```