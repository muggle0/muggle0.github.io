---
title: sentinel 持久化
date: 2021-07-26 12:23:21
tags: 中间件
---

我们之前配置的流控规则都是存储在应用的内存中的，这种方式明显无法满足我们实际开发的需求，一旦项目被重启，流控规则就被初始化了，需要我们再次去重新配置，因此规则的持久化就显得很有必要了。

本节会介绍几类主流持久化方式并对自定义持久化做介绍
<!-- more -->
### 文件持久化

文件持久化是通过 sentinel spi 扩展点来加载本地文件中的持久化数据到内存中，它依赖接口 `InitFunc`，对于非spring项目这种方式可以很便捷的实现
文件持久化。

实现文件持久化首先要自定义一个类并实现`InitFunc` 接口：

```java

public class MyflieInitFunc implements InitFunc {
    @Override
    public void init() throws Exception {
        URL resource = MyflieInitFunc.class.getClassLoader().getResource("");
        File file = new File(resource.getPath()+"/config/flow.json");
        File fileParent = file.getParentFile();
        if(!fileParent.exists()){
            fileParent.mkdirs();
        }
        if (!file.exists()){
            file.createNewFile();
        }
        ReadableDataSource<String, List<FlowRule>> flowReadDataSource = new FileRefreshableDataSource<>(
            resource.getPath()+"/config/flow.json",
            source -> JSON.parseObject(
                source,
                new TypeReference<List<FlowRule>>() {
                }
            ));
        FlowRuleManager.register2Property(flowReadDataSource.getProperty());
        WritableDataSource<List<FlowRule>> flowWriteDataSource = new FileWritableDataSource<>(
            resource.getPath()+"/config/flow.json",
            t->JSON.toJSONString(t)
        );
        WritableDataSourceRegistry.registerFlowDataSource(flowWriteDataSource);
    }
}
```

然后在resources 文件夹下新建文件 `META-INF\services\com.alibaba.csp.sentinel.init.InitFunc` 
内容为`MyflieInitFunc` 的类路径：
```properties
com.muggle.sentinel.config.MyflieInitFunc
```

完成以上步骤后，文件持久化的方式就配置完成了。

`InitFunc` 的资源初始化方法 `init()` 并不是在项目启动的时候调用的，而是在首次产生流控数据的时候调用的，
也就是说它是一个懒加载的方法。
在文件持久化配置中，`FileRefreshableDataSource` , `FileWritableDataSource` , `FlowRuleManager` 这三个类是有必要去熟识的。

- FlowRuleManager 流控规则管理器，用于对流控规则的加载和管理，每类规则都有对应的管理器，后文会介绍。
- FileRefreshableDataSource 流控规则读取及刷新的类，该类配置到sentinel中后会定时拉取流控文件中的流控规则
- FileWritableDataSource 流控规则写入类，当我们在控制台编辑新的流控规则后，控制台会将规则推送给应用，应用接收到推送的规则后，
会通过该类将数据写入流控文件中

### `FlowRuleManager` 源码分析

```java

public class FlowRuleManager {
    private static final AtomicReference<Map<String, List<FlowRule>>> flowRules = new AtomicReference();
    private static final FlowRuleManager.FlowPropertyListener LISTENER = new FlowRuleManager.FlowPropertyListener();
    private static SentinelProperty<List<FlowRule>> currentProperty = new DynamicSentinelProperty();
    private static final ScheduledExecutorService SCHEDULER = Executors.newScheduledThreadPool(1, new NamedThreadFactory("sentinel-metrics-record-task", true));
     
    public static List<FlowRule> getRules() {
       
        List<FlowRule> rules = new ArrayList();
        Iterator var1 = ((Map)flowRules.get()).entrySet().iterator();

        while(var1.hasNext()) {
            Entry<String, List<FlowRule>> entry = (Entry)var1.next();
            rules.addAll((Collection)entry.getValue());
        }

        return rules;
    }
    
    public static void loadRules(List<FlowRule> rules){
         currentProperty.updateValue(rules);
    }
    
     public static boolean hasConfig(String resource) {
         return ((Map)flowRules.get()).containsKey(resource);
    }
}
```
该类的静态属性包括 流控规则数组 `flowRules` ，用于监控流控规则更新的监听器`LISTENER` , 轮询监听流控配置的线程池`SCHEDULER`,sentinel 配置类`currentProperty`.
而它几个api也很明了，就是对流控规则的增删改查。

### `FileRefreshableDataSource` 源码分析

`FileRefreshableDataSource` 继承了`AutoRefreshDataSource`,而`AutoRefreshDataSource` 中有一个线程池 `service` 用于拉取 文件中存储的规则
以及拉取间隔 `recommendRefreshMs` .
：

```java

public abstract class AutoRefreshDataSource<S, T> extends AbstractDataSource<S, T> {
    private ScheduledExecutorService service;
    protected long recommendRefreshMs = 3000L;

    public AutoRefreshDataSource(Converter<S, T> configParser) {
        super(configParser);
        this.startTimerService();
    }
......
     private void startTimerService() {
            this.service = Executors.newScheduledThreadPool(1, new NamedThreadFactory("sentinel-datasource-auto-refresh-task", true));
            this.service.scheduleAtFixedRate(new Runnable() {
                public void run() {
                    try {
                        if (!AutoRefreshDataSource.this.isModified()) {
                            return;
                        }
    
                        T newValue = AutoRefreshDataSource.this.loadConfig();
                        AutoRefreshDataSource.this.getProperty().updateValue(newValue);
                    } catch (Throwable var2) {
                        RecordLog.info("loadConfig exception", var2);
                    }
    
                }
            }, this.recommendRefreshMs, this.recommendRefreshMs, TimeUnit.MILLISECONDS);
        }

}
```
我们重点关注 `startTimerService` 这个方法,这个方法是在构造器里面调用的，也就是说当你new 一个 `FileRefreshableDataSource` 时就会调用该方法

该方法就是通过线程池定时调用`isModified` 方法判断配置是否更新过，如果更新了就同步更新到父类属性 `SentinelProperty` 中，代码对应:

```java
 AutoRefreshDataSource.this.getProperty().updateValue(newValue)
```
不难判读出，父类抽象类的`property` 属性才是真正的获取规则提供拦截判断的关键属性。后文也会用到这个知识点，这里记一下。

我们可以看一下 `FileRefreshableDataSource` 构造函数：

```java

 public FileRefreshableDataSource(File file, Converter<String, T> configParser) throws FileNotFoundException {
        this(file, configParser, 3000L, 1048576, DEFAULT_CHAR_SET);
    }

    public FileRefreshableDataSource(String fileName, Converter<String, T> configParser) throws FileNotFoundException {
        this(new File(fileName), configParser, 3000L, 1048576, DEFAULT_CHAR_SET);
    }

    public FileRefreshableDataSource(File file, Converter<String, T> configParser, int bufSize) throws FileNotFoundException {
        this(file, configParser, 3000L, bufSize, DEFAULT_CHAR_SET);
    }

    public FileRefreshableDataSource(File file, Converter<String, T> configParser, Charset charset) throws FileNotFoundException {
        this(file, configParser, 3000L, 1048576, charset);
    }

    public FileRefreshableDataSource(File file, Converter<String, T> configParser, long recommendRefreshMs, int bufSize, Charset charset) 
```

不难看出，如果在 new `FileRefreshableDataSource` 时不指定刷新间隔就取默认值 3000 毫秒。

### `FileWritableDataSource` 源码分析

```java

public class FileWritableDataSource<T> implements WritableDataSource<T> {
    private static final Charset DEFAULT_CHARSET = Charset.forName("UTF-8");
    private final Converter<T, String> configEncoder;
    private final File file;
    private final Charset charset;
    private final Lock lock;
    
    public void write(T value) throws Exception {
        this.lock.lock();
        try {
            String convertResult = (String)this.configEncoder.convert(value);
            FileOutputStream outputStream = null;

            try {
                outputStream = new FileOutputStream(this.file);
                byte[] bytesArray = convertResult.getBytes(this.charset);
                RecordLog.info("[FileWritableDataSource] Writing to file {}: {}", new Object[]{this.file, convertResult});
                outputStream.write(bytesArray);
                outputStream.flush();
            } finally {
                if (outputStream != null) {
                    try {
                        outputStream.close();
                    } catch (Exception var16) {
                    }
                }

            }
        } finally {
            this.lock.unlock();
        }
    }
}

```
代码结构也很了然，一个数据转换器，一个 file 一个lock ,当框架调用 `write` 方法时上锁并往 file中写配置。

分析得差不多了，让我们看看实战效果吧；

首先启动项目和控制台，然后在控制台上配置一个流控规则，可以观察到项目规则存储文件中多了点内容：
![2](/images/sentinel2.jpg)

文件中新增的数据：

```json
[{"clusterConfig":{"acquireRefuseStrategy":0,"clientOfflineTime":2000,"fallbackToLocalWhenFail":true,"resourceTimeout":2000,"resourceTimeoutStrategy":0,"sampleCount":10,"strategy":0,"thresholdType":0,"windowIntervalMs":1000},"clusterMode":false,"controlBehavior":0,"count":1.0,"grade":1,"limitApp":"default","maxQueueingTimeMs":500,"resource":"test","strategy":0,"warmUpPeriodSec":10}]
```

我们重启项目和控制台规则也不会丢失，规则持久化生效。

通过分析我们知道，这种持久化方式是一种拉模式，胜在配置简单，不需要外部数据源就能完成流控数据的持久化。由于规则是用 FileRefreshableDataSource 定时更新的，所以规则更新会有延迟。
如果FileRefreshableDataSource定时时间过大，可能长时间延迟；如果FileRefreshableDataSource过小，又会影响性能；
因为规则存储在本地文件，如果需要迁移微服务，那么需要把规则文件一起迁移，否则规则会丢失。

文件持久化能应付我们需求的大部分场景，但对于微服务而言是不那么满足要求的；
因为文件持久化就必定要求我们在服务器上提供一个用于存储配置文件的文件夹，而微服务项目大部分情况是容器部署，这就让文件持久化显得不那么好用了。

为此，官方提供了自定义的持久化maven依赖：
```xml
        <dependency>
            <groupId>com.alibaba.csp</groupId>
            <artifactId>sentinel-datasource-extension</artifactId>
        </dependency>

```
以及在这个依赖的基础上开发的以CONSUL NACOS REDIS 作为数据源的maven 依赖：

```xml
        <dependency>
            <artifactId>sentinel-datasource-consul</artifactId>
            <groupId>com.alibaba.csp</groupId>
        </dependency>
        <dependency>
            <artifactId>sentinel-datasource-redis</artifactId>
            <groupId>com.alibaba.csp</groupId>
        </dependency>

        <dependency>
            <artifactId>sentinel-datasource-nacos</artifactId>
            <groupId>com.alibaba.csp</groupId>
        </dependency>

```
### nacos持久化
以上三种种持久化不同于文件持久化，它们是推模式的，而且迁移部署起来更为方便，符合微服务的特性。接下来我们就以nacos持久化为例来学习一下这种方式是怎么配置的。

首先引入 nacos 相关依赖依赖：
```xml

        <dependency>
            <artifactId>sentinel-datasource-nacos</artifactId>
            <groupId>com.alibaba.csp</groupId>
        </dependency>
```
然后通过`FlowRuleManager` 注册数据源就ok了
```java
        ReadableDataSource<String, List<FlowRule>> flowRuleDataSource = new NacosDataSource<>(remoteAddress, groupId, dataId,
            source -> JSON.parseObject(source, new TypeReference<List<FlowRule>>() {
            }));
        FlowRuleManager.register2Property(flowRuleDataSource.getProperty());
```
remoteAddress 是nacos 的地址； groupId和dataId均为nacos配置中心的属性，在创建配置项的时候由使用者自定义，如图为在nacos创建配置项的截图：

![3](/images/sentinel3.jpg)


启动nacos，启动我们的项目和控制台，然后修改nacos中的配置项，就能再控制台上观测到规则变化，nacos中存储的规则也是json,我们可以把文件持久化教程中产生json
复制进去，这里就不在赘述。

这种模式是推模式，优点是这种方式有更好的实时性和一致性保证。因为我们和文件持久化比起来少注册了一个与`FileWritableDataSource` 对应的类，
也就是说应用中更新的规则不能反写到nacos,只能通过nacos读取到配置；因此我们在控制台上修改的规则也不会持久化到nacos中。这样设计是合理的，因为nacos作为
配置中心不应该允许应用去反写自己的配置。

## 源码分析

因为文件持久化分析了一部分源码，因此这里不会对源码分析太多，只简单的介绍它是如何去读取到配置的。


```java

public class NacosDataSource<T> extends AbstractDataSource<String, T> {

    private static final int DEFAULT_TIMEOUT = 3000;
    private final ExecutorService pool;
    private final Listener configListener;
    private final String groupId;
    private final String dataId;
    private final Properties properties;
    private ConfigService configService;

    public NacosDataSource(final Properties properties, final String groupId, final String dataId, Converter<String, T> parser) {
        super(parser);
        this.pool = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new ArrayBlockingQueue(1), new NamedThreadFactory("sentinel-nacos-ds-update"), new DiscardOldestPolicy());
        this.configService = null;
        if (!StringUtil.isBlank(groupId) && !StringUtil.isBlank(dataId)) {
            AssertUtil.notNull(properties, "Nacos properties must not be null, you could put some keys from PropertyKeyConst");
            this.groupId = groupId;
            this.dataId = dataId;
            this.properties = properties;
            this.configListener = new Listener() {
                public Executor getExecutor() {
                    return NacosDataSource.this.pool;
                }

                public void receiveConfigInfo(String configInfo) {
                    RecordLog.info("[NacosDataSource] New property value received for (properties: {}) (dataId: {}, groupId: {}): {}", new Object[]{properties, dataId, groupId, configInfo});
                    T newValue = NacosDataSource.this.parser.convert(configInfo);
                    NacosDataSource.this.getProperty().updateValue(newValue);
                }
            };
            this.initNacosListener();
            this.loadInitialConfig();
        } else {
            throw new IllegalArgumentException(String.format("Bad argument: groupId=[%s], dataId=[%s]", groupId, dataId));
        }
    }
}
```
我们看它的构造方法，创建了一个线程池，然后通过这个线程池 new 了一个nacos的Listener，Listener是一个监听器，initNacosListener() 方法是将监听器
注册到 nacos的configService 里面，通过这个监听器去监听nacos的配置变化，当配置发生更新的时候，调用监听器的 `receiveConfigInfo` 方法：

```java
public void receiveConfigInfo(String configInfo) {
    RecordLog.info("[NacosDataSource] New property value received for (properties: {}) (dataId: {}, groupId: {}): {}", new Object[]{properties, dataId, groupId, configInfo});
    T newValue = NacosDataSource.this.parser.convert(configInfo);
    NacosDataSource.this.getProperty().updateValue(newValue);
}

```

前面分析文件持久话我们就分析过，配置最终要被更新到父类的`property` 属性里面，再这里我们也看到了同样的代码。