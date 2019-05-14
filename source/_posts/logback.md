---
title: ' logback深度使用'
date: 2019-03-28 09:44:50
tags: log
---


##### 作者：muggle

Logback是由log4j创始人设计的另一个开源日志组件,分为三个模块：

1. logback-core：其它两个模块的基础模块

2. logback-classic：它是log4j的一个改良版本，同时它完整实现了slf4j API使你可以很方便地更换成其它日志系统如log4j或JDK14 Logging

3. logback-access：访问模块与Servlet容器集成提供通过Http来访问日志的功能
在springboot中我们通过xml配置来操作logback

<!--more-->
springboot中logback的默认配置文件名称为logback-spring.xml，若需要指定xml名称，需在application.properties（application.yml）中配置logging.config=xxxx.xml
现在贴出一份logback的xml配置，可直接使用，懒得看的小伙伴复制粘贴到你的项目中去体验吧
```xml
<?xml version="1.0" encoding="UTF-8" ?>


<configuration scan="true" scanPeriod="60 seconds" debug="false">

    <jmxConfigurator/>

    <property name="log_dir" value="logs"/>
    <property name="maxHistory" value="100"/>

    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>
                %d{yyyy-MM-dd HH:mm:ss.SSS} %highlight([%-5level]) %logger - %msg%n
            </pattern>
        </encoder>
    </appender>
    <appender name="logs" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>
                ${log_dir}/%d{yyyy-MM-dd}-poseidon.log
            </fileNamePattern>
            <maxHistory>${maxHistory}</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>
                %d{yyyy-MM-dd HH:mm:ss.SSS} %highlight([%-5level]) %logger - %msg%n
            </pattern>
        </encoder>
    </appender>

    <appender name="runningTime-file" class="ch.qos.logback.core.rolling.RollingFileAppender">

        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${log_dir}/runningTime/%d{yyyy-MM-dd}-poseidon.log</fileNamePattern>
            <maxHistory>${maxHistory}</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%-5level] %logger - %msg%n</pattern>
        </encoder>
    </appender>
    <appender name="runningTime-console" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>
                %d{yyyy-MM-dd HH:mm:ss.SSS} [%-5level] %logger - %msg%n
            </pattern>
        </encoder>
    </appender>
    <logger name="runningTime" level="info" additivity="false">
        <!--<appender-ref ref="runningTime-file"/>-->
        <appender-ref ref="runningTime-console"/>
    </logger>
<!--  可能会抛出方言异常 两个解决方案 配置方言或者换连接池 换druid不会有这个异常-->
    <appender name="requestLog-db" class="ch.qos.logback.classic.db.DBAppender">
        <connectionSource class="ch.qos.logback.core.db.DataSourceConnectionSource">
            <dataSource class="org.apache.commons.dbcp.BasicDataSource">
                <driverClassName>com.mysql.cj.jdbc.Driver</driverClassName>
                <url>jdbc:mysql://xxx/xxxx?characterEncoding=UTF-8</url>
                <username>xx</username>
                <password>xxxx</password>
            </dataSource>
        </connectionSource>
        <!--<sqlDialect class="ch.qos.logback.core.db.dialect.MySQLDialect" />-->
    </appender>
    <!--异步配置-->
    <!--<appender name="requestLog-file" class="ch.qos.logback.core.rolling.RollingFileAppender">
         <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
             <fileNamePattern>${log_dir}/requestLog/%d{yyyy-MM-dd}-poseidon.log</fileNamePattern>
             <maxHistory>${maxHistory}</maxHistory>
         </rollingPolicy>
         <encoder>
             <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%-5level] %logger - %msg%n</pattern>
         </encoder>
     </appender>-->
    <!-- <appender name="request-asyn" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="requestLog-file"/>
    </appender> -->
    <appender name="logs-asyn" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="logs"/>
    </appender>
    <logger name="requestLog" level="info" additivity="false">
        <!--<appender-ref ref="requestLog-file"/>-->
        <!-- DBAppender 查看可知其父类dbappenderbase继承了UnsynchronizedAppenderBase<E> 所以dbappender本身是异步的 无需配置异步-->
        <appender-ref ref="requestLog-db"/>
    </logger>
    <root>
        <level value="info"/>
        <appender-ref ref="console"/>
        <!--<appender-ref ref="logs"/>-->
        <appender-ref ref="logs-asyn"/>
    </root>
</configuration>
```

我们可以看到xml中有四种节点
appender，logger，root,configuration
#### 节点解读

configuration包含三个属性：

1. scan: 当此属性设置为true时，配置文件如果发生改变，将会被重新加载，默认值为true。
2. scanPeriod: 设置监测配置文件是否有修改的时间间隔，如果没有给出时间单位，默认单位是毫秒。当scan为true时，此属性生效。默认的时间间隔为1分钟。
3. debug: 当此属性设置为true时，将打印出logback内部日志信息，实时查看logback运行状态。默认值为false。
4.
Logger作为日志的记录器，把它关联到应用的对应的context上后，主要用于存放日志对象，也可以定义日志类型、级别。

Appender主要用于指定日志输出的目的地，目的地可以是控制台、文件、远程套接字服务器、 MySQL、PostreSQL、 Oracle和其他数据库、 JMS和远程UNIX Syslog守护进程等。

root 就是最高级别logger,所有不被指定logger的日志都归root管理。

在slf4j框架下我们使用log是这样的:
```java
 private static final Logger logger= LoggerFactory.getLogger(xxx.class);
```
或者
```java
 private static final Logger logger= LoggerFactory.getLogger("xxxx");
```

可以理解为代码中的getLogger() 方法就是获取xml配置中的logger,如果没有配置相应的logger则为root
比如我配置了：
```xml
<logger name="hhh" level="info" additivity="false">
        <!--<appender-ref ref="requestLog-file"/>-->
        <appender-ref ref="xxx"/>
</logger>
```
那我在获得一个logger时可以这样获得它：
```java
 private static final Logger logger= LoggerFactory.getLogger("hhh");
```
我所输出的日志将被这个logger所管理
logger 上有三个配置 name level additivity
name就是这个logger的名称，level就是这个日志过滤的级别，低于这个级别的日志不输入到对应的appender中；additivity是否向上级logger传递打印信息，默认是true。logger中可以配置多个appender-ref，也就是可以指定多个输出地点。
而root只是特殊的logger，用法上无差别


appender节点：
appender节点是logback配置的关键，其name属性指定其名称，class属性指定实现类，对应得实现类有
```java
ch.qos.logback.core.ConsoleAppender // 以控制台作为输出
ch.qos.logback.core.rolling.RollingFileAppender//以日志文件作为输出
ch.qos.logback.classic.db.DBAppender//以数据库作为输出
net.logstash.logback.appender.LogstashTcpSocketAppender//以logstash作为输出需要引入如下依赖：
ch.qos.logback.classic.AsyncAppender//异步输出 需要定义appender-ref

// logstash依赖
<dependency>
  <groupId>net.logstash.logback</groupId>
  <artifactId>logstash-logback-encoder</artifactId>
  <version>4.11</version>
</dependency>
```

所有的appender 实现ch.qos.logback.core.Appender接口或者 ch.qos.logback.core.UnsynchronizedAppenderBase接口（异步），我们也可以自定义appender来指定日志输出；

在Appender中可以定义哪些节点我们一个个来看：

第一种： ConsoleAppender
如同它的名字一样，这个Appender将日志输出到console，更准确的说是System.out 或者System.err。
它包含的参数如下：

Property | Name	Type |	Description |
---------|-----------| -----------
encoder  | Encoder   | 通常在其pattern里指定日志格式  如： %d{yyyy-MM-dd HH:mm:ss.SSS} %highlight([%-5level]) %logger - %msg%n表示 日期格式 日志级别（高亮）logger的名称 logger的message
target|String|指定输出目标。可选值：System.out 或 System.err。默认值：System.out
withJansi|boolean|是否支持ANSI color codes（类似linux中的shell脚本的输出字符串颜色控制代码）。默认为false。如果设置为true。例如：[31m 代表将前景色设置成红色。在windows中，需要提供"org.fusesource.jansi:jansi:1.9"，而在linux，mac os x中默认支持。

第二种： FileAppender
将日志输出到文件当中，目标文件取决于file属性。是否追加输出，取决于append属性。

Property | Name	Type |	Description |
---------|-----------| -----------
append |	boolean	| 是否以追加方式输出。默认为true。
encoder |	Encoder	|See OutputStreamAppender properties.
file	| String |	指定文件名。注意在windows当中，反斜杠 \ 需要转义，或直接使用 / 也可以。例如 c:/temp/test.logor 或 c:\\temp\\test.log 都可以。没有默认值，如果上层目录不存在，FileAppender会自动创建。
prudent |	boolean|	是否工作在谨慎模式下。在谨慎模式下，FileAppender将会安全写入日志到指定文件，即时在不同的虚拟机jvm中有另一个相同的FileAppender实例。默认值：fales;设置为true，意味着append会被自动设置成true。prudent依赖于文件排它锁。实验表明，使用文件锁，会增加3倍的日志写入消耗。比如说，当prudent模式为off，写入一条日志到文件只要10毫秒，但是prudent为真，则会接近30毫秒。prudent 模式实际上是将I/O请求序列化，因此在I/O数量较大，比如说100次/s或更多的时候，带来的延迟也会显而易见，所以应该避免。在networked file system（远程文件系统）中，这种消耗将会更大，可能导致死锁。

第三个： RollingFileAppender

RollingFileAppender继承自FileAppender，提供日志目标文件自动切换的功能。例如可以用日期作为日志分割的条件。
RollingFileAppender有两个重要属性，RollingPolicy负责怎么切换日志，TriggeringPolicy负责何时切换。为了使RollingFileAppender起作用，这两个属性必须设置，但是如果RollingPolicy的实现类同样实现了TriggeringPolicy接口，则也可以只设置RollingPolicy这个属性。
下面是它的参数：

Property | Name	Type |	Description |
---------|-----------| -----------
file |	String |	指定文件名。注意在windows当中，反斜杠 \ 需要转义，或直接使用 / 也可以。例如 c:/temp/test.logor 或 c:\\temp\\test.log 都可以。没有默认值，如果上层目录不存在，FileAppender会自动创建。
append	|boolean	|是否以追加方式输出。默认为true。
encoder	| Encoder	| See OutputStreamAppender properties.
rollingPolicy |	RollingPolicy	| 当发生日志切换时，RollingFileAppender的切换行为。例如日志文件名的修改
triggeringPolicy	| TriggeringPolicy	| 决定什么时候发生日志切换，例如日期，日志文件大小到达一定值
prudent	| boolean	|FixedWindowRollingPolicy 不支持prudent模式。TimeBasedRollingPolicy 支持prudent模式，但是需要满足一下两条约束：在prudent模式中，日志文件的压缩是不被允许，不被支持的。不能设置file属性。

第四个：SocketAppender及SSLSocketAppender（未尝试过）

到目前为止我们讲的appender都只能将日志输出到本地资源。与之相对的，SocketAppender就是被设计用来输出日志到远程实例中的。SocketAppender输出日志采用明文方式，SSLSocketAppender则采用加密方式传输日志。
被序列化的日志事件的类型是 LoggingEventVO 继承ILoggingEvent接口。远程日志记录并非是侵入式的。在反序列化接收后，日志事件就可以好像在本地生成的日志一样处理了。多个SockerAppender可以向同一台日志服务器发送日志。SocketAppender并不需要关联一个Layout，因为它只是发送序列化的日志事件给远程日志服务器。SocketAppender的发送操作是基于TCP协议的。因此如果远程服务器是可到达的，则日志会被其处理，如果远程服务器宕机或不可到达，那么日志将会被丢弃。等到远程服务器复活，日志发送将会透明的重新开始。这种透明式的重连，是通过一个“连接“线程周期性的尝试连接远程服务器实现的。
Logging events会由TCP协议实现自动缓冲。这意味着，如果网络速度比日志请求产生速度快，则网络速度并不会影响应用。但如果网络速度过慢，则网络速度则会变成限制，在极端情况下，如果远程日志服务器不可到达，则会导致应用最终阻塞。不过，如果服务器可到达，但是服务器宕机了，这种情况，应用不会阻塞，而只是丢失一些日志事件而已。
需要注意的是，即使SocketAppender没有被logger链接，它也不会被gc回收，因为他在connector thread中任然存在引用。一个connector thread 只有在网络不可达的情况下，才会退出。为了防止这个垃圾回收的问题，我们应该显示声明关闭SocketAppender。长久存活并创建/销毁大量的SocketAppender实例的应用，更应该注意这个问题。不过大多数应用可以忽略这个问题。如果JVM在SocketAppender关闭之前将其退出，又或者是被垃圾回收，这样子可能导致丢失一些还未被传输，在管道中等待的日志数据。为了防止避免日志丢失，经常可靠的办法就是调用SocketAppender的close方法，或者调用LoggerContext的stop方法，在退出应用之前。

下面我们来看看SocketAppender的属性：

Property | Name	Type |	Description |
---------|-----------| -----------
includeCallerData |	boolean	|是否包含调用者的信息如果为true，则以下日志输出的 ?:? 会替换成调用者的文件名跟行号，为false，则为问号。2019-01-06 17:37:30,968 DEBUG [Thread-0] [?:?] chapters.appenders.socket.SocketClient2 - Hi
port |	int	| 端口号
reconnectionDelay	| Duration	| 重连延时，如果设置成“10 seconds”，就会在连接u武器失败后，等待10秒，再连接。默认值：“30 seconds”。如果设置成0，则关闭重连功能。
queueSize	| int	| 设置缓冲日志数，如果设置成0，日志发送是同步的，如果设置成大于0的值，会将日志放入队列，队列长度到达指定值，在统一发送。可以加大服务吞吐量。
eventDelayLimit |	Duration |	设置日志超时丢弃时间。当设置“10 seconds”类似的值，如果日志队列已满，而服务器长时间来不及接收，当滞留时间超过10 seconds，日志就会被丢弃。默认值： 100 milliseconds
remoteHost |	String |	远程日志服务器的IP
ssl	| SSLConfiguration | 只在SSLSocketAppender包含该属性节点。提供SSL配置，详情见 Using SSL.

标准的Logback Classic包含四个可供使用的Receiver用来接收来自SocketAppender的logging evnets。

第五个： SMTPAppender

SMTPAppender 可以将logging event存放在一个或多个固定大小的缓冲区中，然后在用户指定的event到来之时，将适当的大小的logging event以邮件方式发送给运维人员。
详细属性如下：

Property | Name	Type |	Description |
---------|-----------| -----------
smtpHost |	String	| SMTP server的地址，必需指定。如网易的SMTP服务器地址是： smtp.163.com
smtpPort |	int	| SMTP server的端口地址。默认值：25
to	| String |	指定发送到那个邮箱，可设置多个<to>属性，指定多个目的邮箱
from |	String |	指定发件人名称。如果设置成“muggle &lt;hh@moral.org&gt; ”，则邮件发件人将会是“muggle <hh@moral.org> ”
subject |	String |指定emial的标题，它需要满足PatternLayout中的格式要求。如果设置成“Log: %logger - %msg”，就案例来讲，则发送邮件时，标题为“Log: com.foo.Bar - Hello World ”。 默认值："%logger{20} - %m".
discriminator	| Discriminator	| 通过Discriminator, SMTPAppender可以根据Discriminator的返回值，将到来的logging event分发到不同的缓冲区中。默认情况下，总是返回相同的值来达到使用一个缓冲区的目的。
evaluator |	IEvaluator	| 指定触发日志发送的条件。通过<evaluator class=... />指定EventEvaluator接口的实现类。默认情况下SMTPAppeender使用的是OnErrorEvaluator，表示当发送ERROR或更高级别的日志请求时，发送邮件。Logback提供了几个evaluators：OnErrorEvaluator、OnMarkerEvaluator、JaninoEventEvaluator、GEventEvaluator（功能强大）
cyclicBufferTracker |	CyclicBufferTracker	| 指定一个cyclicBufferTracker跟踪cyclic buffer。它是基于discriminator的实现的。如果你不指定，默认会创建一个CyclicBufferTracker ，默认设置cyclic buffer大小为256。你也可以手动指定使用默认的CyclicBufferTracker，并且通过<bufferSize>属性修改默认的缓冲区接收多少条logging event。
username	| String |	发送邮件账号，默认为null
password |	String |	发送邮件密码，默认为null
STARTTLS	| boolean	|如果设置为true，appender会尝试使用STARTTLS命令，如果服务端支持，则会将明文连接转换成加密连接。需要注意的是，与日志服务器连接一开始是未加密的。默认值：false
SSL	| boolean	| 如果设置为true，appender将会使用SSL连接到日志服务器。 默认值：false
charsetEncoding |	String	|指定邮件信息的编码格式 默认值：UTF-8
localhost	| String |	如果smtpHost没有正确配置，比如说不是完整的地址。这时候就需要localhost这个属性提供服务器的完整路径（如同java中的完全限定名 ），详情参考com.sun.mail.smtp 中的mail.smtp.localhost属性
asynchronousSending	| boolean	| 这个属性决定email的发送是否是异步。默认：true，异步发送但是在某些情况下，需要以同步方式发送错误日志的邮件给管理人员，防止不能及时维护应用。
includeCallerData |	boolean	|默认：false 指定是否包含callerData在日志中
sessionViaJNDI |	boolean	| SMTPAppender依赖javax.mail.Session来发送邮件。默认情况下，sessionViaJNDI为false。javax.mail.Session实例的创建依赖于SMTPAppender本身的配置信息。如果设置为true，则Session的创建时通过JNDI获取引用。这样做的好处可以让你的代码复用更好，让配置更简洁。需要注意的是，如果使用JNDI获取Session对象，需要保证移除mail.jar以及activation.jar这两个jar包
jndiLocation |	String	| 如果sessionViaJNDI设置为true，则jndiLocation指定JNDI的资源名，默认值为："java:comp/env/mail/Session"

SMTPAppender只保留最近的256条logging events 在循环缓冲区中，当缓冲区慢，就会开始丢弃最老的logging event。因此不管什么时候，SMTPAppender一封邮件最多传递256条日志事件。SMTPAppender依赖于JavaMail API。而JavaMail API又依赖于IOC框架（依赖注入）。

第六个：DBAppender

 DBAppender 可以将日志事件插入到3张数据表中。它们分别是logging_event，logging_event_property，logging_event_exception。这三张数据表必须在DBAppender工作之前存在。它们的sql脚本可以在 logback-classic/src/main/java/ch/qos/logback/classic/db/script folder 这个目录下找到。这个脚本对大部分SQL数据库都是有效的，除了少部分，少数语法有差异需要调整。
下面是logback与常见数据库的支持信息：

RDBMS	| tested version(s)	| tested JDBC driver version(s)| 	supports getGeneratedKeys() method |	is a dialect provided by logback
----------|----------|--------|----------|----
DB2 |	untested |	untested |	unknown |	NO
H2 |	--| - |	unknown	| YES
HSQL |-- |	-	| NO |	YES
Microsoft SQL Server |	-- | -- |	YES	| YES
MySQL |	5.7	|  	|YES|	YES
PostgreSQL | --|-- |	NO|	YES
Oracle	|--|--|	YES	|YES
SQLLite	|--|	-|	unknown	|YES
Sybase |--|		-	|unknown|	YES


下面给出三张表的sql语句：
```sql
BEGIN;
DROP TABLE IF EXISTS logging_event_property;
DROP TABLE IF EXISTS logging_event_exception;
DROP TABLE IF EXISTS logging_event;
COMMIT;

BEGIN;
CREATE TABLE logging_event
  (
    timestmp         BIGINT NOT NULL,
    formatted_message  TEXT NOT NULL,
    logger_name       VARCHAR(254) NOT NULL,
    level_string      VARCHAR(254) NOT NULL,
    thread_name       VARCHAR(254),
    reference_flag    SMALLINT,
    arg0              VARCHAR(254),
    arg1              VARCHAR(254),
    arg2              VARCHAR(254),
    arg3              VARCHAR(254),
    caller_filename   VARCHAR(254) NOT NULL,
    caller_class      VARCHAR(254) NOT NULL,
    caller_method     VARCHAR(254) NOT NULL,
    caller_line       CHAR(4) NOT NULL,
    event_id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY
  );
COMMIT;


BEGIN;
CREATE TABLE logging_event_property
  (
    event_id       BIGINT NOT NULL,
    mapped_key        VARCHAR(254) NOT NULL,
    mapped_value      TEXT,
    PRIMARY KEY(event_id, mapped_key),
    FOREIGN KEY (event_id) REFERENCES logging_event(event_id)
  );
COMMIT;


BEGIN;
CREATE TABLE logging_event_exception
  (
    event_id         BIGINT NOT NULL,
    i                SMALLINT NOT NULL,
    trace_line       VARCHAR(254) NOT NULL,
    PRIMARY KEY(event_id, i),
    FOREIGN KEY (event_id) REFERENCES logging_event(event_id)
  );
COMMIT;
```

第七个： AsyncAppender

AsyncAppender记录ILoggingEvents的方式是异步的。它仅仅相当于一个event分配器，因此需要配合其他appender才能有所作为。

需要注意的是：AsyncAppender将event缓存在 BlockingQueue ，一个由AsyncAppender创建的工作线程，会一直从这个队列的头部获取events，然后将它们分配给与AsyncAppender唯一关联的Appender中。默认情况下，如果这个队列80%已经被占满，则AsyncAppender会丢弃等级为 TRACE，DEBUG，INFO这三个等级的日志事件。
在应用关闭或重新部署的时候，AsyncAppender一定要被关闭，目的是为了停止，回收再利用worker thread，和刷新缓冲队列中logging events。那如果关闭AsyncAppender呢？可以通过关闭LoggerContext来关闭所有appender，当然也包括AsyncAppender了。AsyncAppender会在maxFlushTime属性设置的时间内等待Worker thread刷新全部日志event。如果你发现缓冲的event在关闭LoggerContext的时候被丢弃，这时候你就也许需要增加等待的时间。将maxFlushTime设置成0，就是AsyncAppender一直等待直到工作线程将所有被缓冲的events全部刷新出去才执行才结束。
根据JVM退出的模式，工作线程worker thread处理被缓冲的events的工作是可以被中断的，这样就导致了剩余未处理的events被搁浅。这种现象通常的原因是当LoggerContext没有完全关闭，或者当JVM终止那些非典型的控制流（不明觉厉）。为了避免工作线程的因为这些情况而发生中断，一个shutdown hook（关闭钩子）可以被插入到JVM运行的时候，这个钩子的作用是在JVM开始shutdown刚开始的时候执行关闭 LoggerContext的任务。

下面是AsyncAppender的属性表

Property | Name	Type |	Description |
---------|-----------| -----------
queueSize	| int	| 设置blocking queue的最大容量，默认是256条events
discardingThreshold	| int	| 默认，当blocking queue被占用80%以上，AsyncAppender就会丢弃level为 TRACE，DEBUG，INFO的日志事件，如果要保留所有等级的日志，需要设置成0
includeCallerData	| boolean	| 提取CallerData代价比较昂贵，为了提高性能，caller data默认不提供。只有一些获取代价较低的数据，如线程名称，MDC值才会被保留。如果设置为true，就会包含caller data
maxFlushTime | 	int	|设置最大等待刷新事件，单位为miliseconds(毫秒)。当LoggerContext关闭的时候，AsyncAppender会在这个时间内等待工作线程完成events的flush工作，超时未处理的events将会被抛弃。
neverBlock |	boolean |	默认为false，如果队列被填满，为了处理所有日志，就会阻塞的应用。如果为true，为了不阻塞你的应用，也会选择抛弃一些message。

默认情况下，event queue最大的容量是256。如果队列被填充满那么就会阻塞你的应用，直到队列能够容纳新的logging event。所以当AsyncAppender工作在队列满的情况下，可以称作伪同步。
在以下四种情况下容易导致AsyncAppender伪同步状态的出现：

1. 应用中存在大量线程
2. 每秒产生大量的logging events
3. 每一个logging event都存在大量的数据
4. 子appender中存在很高的延迟

为了避免伪同步的出现，提高queueSizes普遍有效，但是就消耗了应用的可用内存。

下面列出一些 appender配置示例：

```xml

<configuration>
  <appender name="FILE" class="ch.qos.logback.core.FileAppender">
    <file>myapp.log</file>
    <encoder>
      <pattern>%logger{35} - %msg%n</pattern>
    </encoder>
  </appender>

  <appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
  </appender>

  <root level="DEBUG">
    <appender-ref ref="ASYNC" />
  </root>
</configuration>

<configuration>

  <appender name="DB" class="ch.qos.logback.classic.db.DBAppender">
    <connectionSource
      class="ch.qos.logback.core.db.DataSourceConnectionSource">
      <dataSource
        class="com.mchange.v2.c3p0.ComboPooledDataSource">
        <driverClass>com.mysql.jdbc.Driver</driverClass>
        <jdbcUrl>jdbc:mysql://${serverName}:${port}/${dbName}</jdbcUrl>
        <user>${user}</user>
        <password>${password}</password>
      </dataSource>
    </connectionSource>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="DB" />
  </root>
</configuration>

<configuration>
  <appender name="EMAIL" class="ch.qos.logback.classic.net.SMTPAppender">
    <smtpHost>smtp.gmail.com</smtpHost>
    <smtpPort>465</smtpPort>
    <SSL>true</SSL>
    <username>YOUR_USERNAME@gmail.com</username>
    <password>YOUR_GMAIL_PASSWORD</password>

    <to>EMAIL-DESTINATION</to>
    <to>ANOTHER_EMAIL_DESTINATION</to> <!-- additional destinations are possible -->
    <from>YOUR_USERNAME@gmail.com</from>
    <subject>TESTING: %logger{20} - %m</subject>
    <layout class="ch.qos.logback.classic.PatternLayout">
      <pattern>%date %-5level %logger{35} - %message%n</pattern>
    </layout>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="EMAIL" />
  </root>
</configuration>

<configuration>
  <appender name="EMAIL" class="ch.qos.logback.classic.net.SMTPAppender">
    <smtpHost>smtp.gmail.com</smtpHost>
    <smtpPort>587</smtpPort>
    <STARTTLS>true</STARTTLS>
    <username>YOUR_USERNAME@gmail.com</username>
    <password>YOUR_GMAIL_xPASSWORD</password>

    <to>EMAIL-DESTINATION</to>
    <to>ANOTHER_EMAIL_DESTINATION</to> <!-- additional destinations are possible -->
    <from>YOUR_USERNAME@gmail.com</from>
    <subject>TESTING: %logger{20} - %m</subject>
    <layout class="ch.qos.logback.classic.PatternLayout">
      <pattern>%date %-5level %logger - %message%n</pattern>
    </layout>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="EMAIL" />
  </root>
</configuration>

SimpleSocketServer需要两个命令行参数，port 和 configFile路径。(该方法待验证)
java ch.qos.logback.classic.net.SimpleSocketServer 6000 \ src/main/java/chapters/appenders/socket/server1.xml

客户端的SocketAppender的简单配置例子：
<configuration>

  <appender name="SOCKET" class="ch.qos.logback.classic.net.SocketAppender">
    <remoteHost>192.168.0.101</remoteHost>
    <port>8888</port>
    <reconnectionDelay>10000</reconnectionDelay>
    <includeCallerData>true</includeCallerData>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="SOCKET" />
  </root>

</configuration>

在服务端使用SimpleSSLSocketServer
java -Djavax.net.ssl.keyStore=src/main/java/chapters/appenders/socket/ssl/keystore.jks \ -Djavax.net.ssl.keyStorePassword=changeit \ ch.qos.logback.classic.net.SimpleSSLSocketServer 6000 \ src/main/java/chapters/appenders/socket/ssl/server.xml

SSLSocketAppender配置
<configuration debug="true">

  <appender name="SOCKET" class="ch.qos.logback.classic.net.SSLSocketAppender">
    <remoteHost>${host}</remoteHost>
    <port>${port}</port>
    <reconnectionDelay>10000</reconnectionDelay>
    <ssl>
      <trustStore>
        <location>${truststore}</location>
        <password>${password}</password>
      </trustStore>
    </ssl>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="SOCKET" />
  </root>

</configuration>

<configuration>

  <appender name="FILE" class="ch.qos.logback.core.FileAppender">
    <file>testFile.log</file>
    <append>true</append>
    <!-- encoders are assigned the type
        ch.qos.logback.classic.encoder.PatternLayoutEncoder by default -->
    <encoder>
      <pattern>%-4relative [%thread] %-5level %logger{35} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="DEBUG">
    <appender-ref ref="FILE" />
  </root>
</configuration>
```
参考：https://blog.csdn.net/tianyaleixiaowu/article/details/73327752

下面基于logback配置做一个请求日志的的封装

功能：记录每次请求的参数和用户ID存入数据库或者elk
问题：javaee规范中request输入输出流都只能被读取一次，所以如果用过滤器或者拦截器读取request中的流都会导致后面的controller无法接受到数据。
所以我们要用原生的aop获得请求参数，切点为controller，这就很好的避开了以上问题。

```java
package com.muggle.poseidon.core.aspect;

import com.muggle.poseidon.manager.UserInfoManager;
import com.muggle.poseidon.utils.RequestUtils;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.Serializable;

/**
 * @program: hiram_erp
 * @description: 日志信息切面
 * @author: muggle
 * @create: 2019-02-21
 **/
@Aspect
@Component
public class LogMessageAspect {

    private final static Logger logger = LoggerFactory.getLogger("requestLog");
//    private final static Logger timeLog = LoggerFactory.getLogger(LogMessageAspect.class);
    private static final ThreadLocal<Long> threadLocal = new ThreadLocal<>();
    @Pointcut("execution(public * com.hiram.erp.controller.*.*(..))")
    public void webLog() {}

    /**
     * 在切点之前织入
     * @param joinPoint
     * @throws Throwable
     */
    @Before("webLog()")
    public void doBefore(JoinPoint joinPoint) throws Throwable {
//        System.out.println("sssssssssssssssssssssssssssssssssssssssssssssssssssss");
       /* // 开始打印请求日志
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = attributes.getRequest();

        // 打印请求相关参数
        // 打印请求 url
        // 请求id
        Long userId=null;
        if (user!=null){
            userId=user.getUserInfo().getUserId();
        }
        logger.info("URL : {}, 登录id: {} ,HTTP Method: {},ip :{},Request Args : {}", request.getRequestURL().toString(),userId, request.getMethod(),request.getRemoteAddr());
*/    }

    /**
     * 在切点之后织入
     * @throws Throwable
     */
    @After("webLog()")
    public void doAfter(JoinPoint joinPoint) throws Throwable {



    }

    /**
     * 环绕
     * @param joinPoint
     * @return
     * @throws Throwable
     */
    @Around("webLog()")
    public Object doAround(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();
        Object result = joinPoint.proceed();
        // 打印出参
//        logger.info("Response Args  : {},", JSONObject.toJSONString(result),new Date());
        // 执行耗时
        // 开始打印请求日志
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = attributes.getRequest();
        HttpServletResponse response = attributes.getResponse();
        String requestURL = request.getRequestURL().toString();
        if (requestURL.contains("/sys/log_info/")){
            return result;
        }
        // 打印请求相关参数
        // 打印请求 url
        // 请求id
        String userId = UserInfoManager.getUserId();

        String url = request.getRequestURL().toString();
        String method = request.getMethod();
        String remoteAddr = RequestUtils.getIpAddr(request);
        Object[] args = joinPoint.getArgs();
//        List<Object> objects=new ArrayList<>();
        StringBuilder stringBuilder = new StringBuilder();
        for (int i=0;i<args.length;i++){
            if (args[i] instanceof Serializable||args[i] instanceof Number ||args[i] instanceof String){
                stringBuilder.append( args[i].toString());
//                objects.add(args[i]);
            }
        }
        logger.info("{\"startTime\":\"{}\",\"url\":\"{}\",\"userId\":\"{}\" ,\"httpMethod\":\"{}\",\"ip\":\"{}\",\"requestArgs\":\"{}\",\"status\":{}}",startTime,url,userId,method,remoteAddr,stringBuilder.toString(),response.getStatus());
        return result;
    }


}

```
对于数据库存储，如果我们希望log存在另外一个数据库中不存在项目里的数据库中，并且可以通过持久化框架查询数据库内信息。我们则可以配置多数据源，如果将日志放在同一个数据库中则直接配置appender就行了，很方便。
多数据源配置mybatis版：

其原理是配置多个sessionfactory,然后根据不同的mapperscan来区分不同mapper对应的数据库

以druid连接池为例

application.yml

```java
log:
  datasource:
    druid:
      url: ${mysql_url}/log?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&allowMultiQueries=true&serverTimezone=GMT%2B8&nullCatalogMeansCurrent=true
      username:
      password:
      driver-class-name: com.mysql.cj.jdbc.Driver
      connectionProperties: druid.stat.mergeSql=true;druid.stat.slowSqlMillis=5000
      filters: stat,wall
      initialSize: 5
      maxActive: 20
      maxPoolPreparedStatementPerConnectionSize: 20
      maxWait: 60000
      minIdle: 5
      poolPreparedStatements: true
      testOnBorrow: false
      testOnReturn: false
      testWhileIdle: true
      timeBetweenEvictionRunsMillis: 60000
      validationQuery: SELECT 1


spring:
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    druid:
      url: ${mysql_url}/hiram_erp?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&allowMultiQueries=true&serverTimezone=GMT%2B8&nullCatalogMeansCurrent=true
      username:
      password:
      driver-class-name: com.mysql.cj.jdbc.Driver
      connectionProperties: druid.stat.mergeSql=true;druid.stat.slowSqlMillis=5000
      filters: stat,wall
      initialSize: 5
      maxActive: 20
      maxPoolPreparedStatementPerConnectionSize: 20
      maxWait: 60000
      minIdle: 5
      poolPreparedStatements: true
      testOnBorrow: false
      testOnReturn: false
      testWhileIdle: true
      timeBetweenEvictionRunsMillis: 60000
      validationQuery: SELECT 1
```

```java

@Configuration
// 主数据库配置 指定mapper位置
@MapperScan(basePackages = {"com.muggle.poseidon.mapper"}, sqlSessionTemplateRef = "sqlSessionTemplate")
public class ManySourceDBConfig {

    @Bean(name = "dataSource")
    // 读取application的配置信息
   @ConfigurationProperties(prefix = "spring.datasource.druid")
   // 最高优先级，表示系统默认使用该配置
    @Primary
    public DataSource dataSource() {
        DruidDataSource druidDataSource = new DruidDataSource();

        List filterList = new ArrayList<>();

        filterList.add(wallFilter());

        druidDataSource.setProxyFilters(filterList);

        return druidDataSource;
    }

    @Bean(name = "sqlSessionFactory")
    @Primary
    public SqlSessionFactory sqlSessionFactory() throws Exception {
        SqlSessionFactoryBean sqlSessionFactoryBean = new SqlSessionFactoryBean();
        sqlSessionFactoryBean.setDataSource(this.dataSource());

        Properties props = new Properties();
        props.setProperty("localCacheScope", "true");
        props.setProperty("lazyLoadingEnabled", "true");
        props.setProperty("aggressiveLazyLoading", "false");
        props.setProperty("jdbcTypeForNull", "NULL");
        sqlSessionFactoryBean.setConfigurationProperties(props);
        sqlSessionFactoryBean.setVfs(SpringBootVFS.class);
        //pageHelper
        Properties properties = new Properties();
        properties.setProperty("reasonable", "true");
        properties.setProperty("supportMethodsArguments", "true");
        properties.setProperty("params", "count=countSql");
        properties.setProperty("pageSizeZero", "true");
        PageInterceptor interceptor = new PageInterceptor();
        interceptor.setProperties(properties);
        sqlSessionFactoryBean.setPlugins(new Interceptor[]{interceptor});
        sqlSessionFactoryBean.setTypeAliasesPackage("com.muggle.poseidon.model");
        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        sqlSessionFactoryBean.setMapperLocations(resolver.getResources("classpath*:/mapper/*.xml"));
        return sqlSessionFactoryBean.getObject();
    }

    @Bean(name = "transactionManager")
    @Primary
    public PlatformTransactionManager transactionManager() {
        return new DataSourceTransactionManager(this.dataSource());
    }

    @Bean(name = "sqlSessionTemplate")
    public SqlSessionTemplate testSqlSessionTemplate(@Qualifier("sqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }

    @Bean
    public ServletRegistrationBean statViewServlet() {
        ServletRegistrationBean druid = new ServletRegistrationBean();
        druid.setServlet(new StatViewServlet());
        druid.setUrlMappings(Collections.singletonList("/druid/*"));
        Map<String, String> params = new HashMap<>();
        params.put("loginUsername", "");
        params.put("loginPassword", "");
        druid.setInitParameters(params);
        return druid;
    }

    @Bean
    public FilterRegistrationBean webStatFilter() {
        FilterRegistrationBean fitler = new FilterRegistrationBean();
        fitler.setFilter(new WebStatFilter());
        fitler.setUrlPatterns(Collections.singletonList("/*"));
        fitler.addInitParameter("exclusions", "*.js,*.gif,*.jpg,*.png,*.css,*.ico,/druid/*");
        return fitler;
    }

    @Bean
    public WallFilter wallFilter() {

        WallFilter wallFilter = new WallFilter();

        wallFilter.setConfig(wallConfig());

        return wallFilter;

    }

    @Bean
    public WallConfig wallConfig() {

        WallConfig config = new WallConfig();

        config.setMultiStatementAllow(true);//允许一次执行多条语句

        config.setNoneBaseStatementAllow(true);//允许非基本语句的其他语句

        return config;

    }

    @Bean
    public ProcessEngineConfiguration processEngineConfiguration() {
        ProcessEngineConfiguration pec = StandaloneProcessEngineConfiguration.createStandaloneProcessEngineConfiguration();
        pec.setDataSource(dataSource());
        //如果表不存在，自动创建表
        pec.setDatabaseSchemaUpdate(ProcessEngineConfiguration.DB_SCHEMA_UPDATE_TRUE);
        //属性asyncExecutorActivate定义为true，工作流引擎在启动时就建立启动async executor线程池
        pec.setAsyncExecutorActivate(false);
        return pec;
    }


    @Bean
    public ProcessEngine processEngine() {
        return processEngineConfiguration().buildProcessEngine();
    }

}

```

log数据库配置

```java



/**
 * @program:
 * @description:
 * @author: muggle
 * @create: 2019-02-23
 **/
@Configuration
// 注意确保主配置无法扫描到这个包
@MapperScan(basePackages = "com.muggle.poseidon.logmapper", sqlSessionTemplateRef  = "test1SqlSessionTemplate")

public class LogDBConfig  {
    @Bean(name = "test1DataSource")
    @ConfigurationProperties(prefix = "log.datasource.druid")
    public DataSource dataSource() {
        DruidDataSource druidDataSource = new DruidDataSource();

        List filterList = new ArrayList<>();

        filterList.add(wallFilter());

        druidDataSource.setProxyFilters(filterList);

        return druidDataSource;
    }

    @Bean(name = "test1SqlSessionFactory")
    public SqlSessionFactory testSqlSessionFactory(@Qualifier("test1DataSource") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new
        // mapper位置，不要和主配置的mapper放到一起
         PathMatchingResourcePatternResolver().getResources("classpath*:/mapper/log/*.xml"));
        return bean.getObject();
    }

    @Bean(name = "test1TransactionManager")
    public DataSourceTransactionManager testTransactionManager(@Qualifier("test1DataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    @Bean(name = "test1SqlSessionTemplate")
    public SqlSessionTemplate testSqlSessionTemplate(@Qualifier("test1SqlSessionFactory") SqlSessionFactory sqlSessionFactory) throws Exception {
        return new SqlSessionTemplate(sqlSessionFactory);
    }

    @Bean
    public WallFilter wallFilter() {

        WallFilter wallFilter = new WallFilter();

        wallFilter.setConfig(wallConfig());

        return wallFilter;

    }
    @Bean
    public WallConfig wallConfig() {

        WallConfig config = new WallConfig();

        config.setMultiStatementAllow(true);//允许一次执行多条语句

        config.setNoneBaseStatementAllow(true);//允许非基本语句的其他语句

        return config;

    }
}

```

多数据源jpa版
```java
package com.muggle.poseidon.config;


import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfig {

    /**
     * 扫描spring.datasource.primary开头的配置信息
     *
     * @return 数据源配置信息
     */
    @Primary
    @Bean(name = "primaryDataSourceProperties")
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }

    /**
     * 获取主库数据源对象
     *
     * @param properties 注入名为primaryDataSourceProperties的bean
     * @return 数据源对象
     */
    @Primary
    @Bean(name = "primaryDataSource")
    public DataSource dataSource(@Qualifier("primaryDataSourceProperties") DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder().build();
    }

    /**
     * 该方法仅在需要使用JdbcTemplate对象时选用
     *
     * @param dataSource 注入名为primaryDataSource的bean
     * @return 数据源JdbcTemplate对象
     */
    @Primary
    @Bean(name = "primaryJdbcTemplate")
    public JdbcTemplate jdbcTemplate(@Qualifier("primaryDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }




}

```

```java
package com.muggle.poseidon.config;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateSettings;
import org.springframework.boot.autoconfigure.orm.jpa.JpaProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.util.Map;


@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        // repository包名
        basePackages = "com.muggle.poseidon.repos",
        // 实体管理bean名称
        entityManagerFactoryRef = "primaryEntityManagerFactory",
        // 事务管理bean名称
        transactionManagerRef = "primaryTransactionManager"
)
public class MainDataBaseConfig {

    /**
     * 扫描spring.jpa.primary开头的配置信息
     *
     * @return jpa配置信息
     */
    @Primary
    @Bean(name = "primaryJpaProperties")
    @ConfigurationProperties(prefix = "spring.jpa")
    public JpaProperties jpaProperties() {
        return new JpaProperties();
    }

    /**
     * 获取主库实体管理工厂对象
     *
     * @param primaryDataSource 注入名为primaryDataSource的数据源
     * @param jpaProperties     注入名为primaryJpaProperties的jpa配置信息
     * @param builder           注入EntityManagerFactoryBuilder
     * @return 实体管理工厂对象
     */
    @Primary
    @Bean(name = "primaryEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(@Qualifier("primaryDataSource") DataSource primaryDataSource
            , @Qualifier("primaryJpaProperties") JpaProperties jpaProperties, EntityManagerFactoryBuilder builder) {
        return builder
                // 设置数据源
                .dataSource(primaryDataSource)
                // 设置jpa配置
                .properties(jpaProperties.getProperties())
                // 设置hibernate配置
                .properties(jpaProperties.getHibernateProperties(new HibernateSettings()))
                // 设置实体包名
                .packages("com.muggle.poseidon.model")
                // 设置持久化单元名，用于@PersistenceContext注解获取EntityManager时指定数据源
                .persistenceUnit("primaryPersistenceUnit")
                .build();
    }

    /**
     * 获取实体管理对象
     *
     * @param factory 注入名为primaryEntityManagerFactory的bean
     * @return 实体管理对象
     */
    @Primary
    @Bean(name = "primaryEntityManager")
    public EntityManager entityManager(@Qualifier("primaryEntityManagerFactory") EntityManagerFactory factory) {
        return factory.createEntityManager();
    }

    /**
     * 获取主库事务管理对象
     *
     * @param factory 注入名为primaryEntityManagerFactory的bean
     * @return 事务管理对象
     */
    @Primary
    @Bean(name = "primaryTransactionManager")
    public PlatformTransactionManager transactionManager(@Qualifier("primaryEntityManagerFactory") EntityManagerFactory factory) {
        return new JpaTransactionManager(factory);
    }
}

​```java
package com.muggle.poseidon.core.config;


import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateSettings;
import org.springframework.boot.autoconfigure.orm.jpa.JpaProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;

@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
        // repository包名
        basePackages = "com.muggle.poseidon.logrep",
        // 实体管理bean名称
        entityManagerFactoryRef = "secondEntityManagerFactory",
        // 事务管理bean名称
        transactionManagerRef = "secondTransactionManager"
)
public class LogDataBaseConfig {

    /**
     * 扫描spring.jpa.second开头的配置信息
     *
     * @return jpa配置信息
     */
    @Bean(name = "secondJpaProperties")
    @ConfigurationProperties(prefix = "spring.aa")
    public JpaProperties jpaProperties() {
        return new JpaProperties();
    }

    /**
     * 获取从库实体管理工厂对象
     *
     * @param secondDataSource 注入名为secondDataSource的数据源
     * @param jpaProperties    注入名为secondJpaProperties的jpa配置信息
     * @param builder          注入EntityManagerFactoryBuilder
     * @return 实体管理工厂对象
     */
    @Bean(name = "secondEntityManagerFactory")
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(@Qualifier("secondDataSource") DataSource secondDataSource
            , @Qualifier("secondJpaProperties") JpaProperties jpaProperties, EntityManagerFactoryBuilder builder) {
        return builder
                // 设置数据源
                .dataSource(secondDataSource)
                // 设置jpa配置
                .properties(jpaProperties.getProperties())
                // 设置hibernate配置
                .properties(jpaProperties.getHibernateProperties(new HibernateSettings()))
                // 设置实体包名
                .packages("com.muggle.poseidon.entity")
                // 设置持久化单元名，用于@PersistenceContext注解获取EntityManager时指定数据源
                .persistenceUnit("secondPersistenceUnit")
                .build();
    }

    /**
     * 获取实体管理对象
     *
     * @param factory 注入名为secondEntityManagerFactory的bean
     * @return 实体管理对象
     */
    @Bean(name = "secondEntityManager")
    public EntityManager entityManager(@Qualifier("secondEntityManagerFactory") EntityManagerFactory factory) {
        return factory.createEntityManager();
    }

    /**
     * 获取从库事务管理对象
     *
     * @param factory 注入名为secondEntityManagerFactory的bean
     * @return 事务管理对象
     */
    @Bean(name = "secondTransactionManager")
    public PlatformTransactionManager transactionManager(@Qualifier("secondEntityManagerFactory") EntityManagerFactory factory) {
        return new JpaTransactionManager(factory);
    }
}

```

```java

package com.muggle.poseidon.core.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class LogDataConfig {
    /**
     * 扫描spring.datasource.second开头的配置信息
     *
     * @return 数据源配置信息
     */
    @Bean(name = "secondDataSourceProperties")
    @ConfigurationProperties(prefix = "spring.ss")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }

    /**
     * 获取从库数据源对象
     *
     * @param properties 注入名为secondDataSourceProperties的beanf
     * @return 数据源对象
     */
    @Bean(name = "secondDataSource")
    public DataSource dataSource(@Qualifier("secondDataSourceProperties") DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder().build();
    }

    /**
     * 该方法仅在需要使用JdbcTemplate对象时选用
     *
     * @param dataSource 注入名为secondDataSource的bean
     * @return 数据源JdbcTemplate对象
     */
    @Bean(name = "secondJdbcTemplate")
    public JdbcTemplate jdbcTemplate(@Qualifier("secondDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}

```

application.properties

```java
server.port=8080
spring.datasource.type=com.alibaba.druid.pool.DruidDataSource
#spring.datasource.url = jdbc:mysql://localhost:3306/test
spring.datasource.driverClassName = com.mysql.cj.jdbc.Driver
spring.datasource.url = jdbc:mysql://119.23.75.58:3306/poseidon?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&allowMultiQueries=true
spring.datasource.username =
spring.datasource.password =
spring.datasource.max-active=20
spring.datasource.max-idle=8
spring.datasource.min-idle=8
spring.datasource.initial-size=10

spring.jpa.database=mysql
spring.jpa.show-sql = true
#配置方言
spring.jpa.database-platform=org.hibernate.dialect.MySQL5Dialect

spring.ss.type=com.alibaba.druid.pool.DruidDataSource
#spring.datasource.url = jdbc:mysql://localhost:3306/test
spring.ss.driverClassName = com.mysql.cj.jdbc.Driver
spring.ss.url = jdbc:mysql://zzzzz/log?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&useSSL=false&allowMultiQueries=true
spring.ss.username =
spring.ss.password =
spring.ss.max-active=20
spring.ss.max-idle=8
spring.ss.min-idle=8
spring.ss.initial-size=10


spring.aa.database=mysql
spring.aa.show-sql = true
#配置方言
spring.aa.database-platform=org.hibernate.dialect.MySQL5Dialect
```


以数据库作为输出配置就算完成了，接下来整合elk系统到我们日志系统中：


先整合logstash

logstash安装和配置：
https://www.elastic.co/cn/downloads/logstash 选择zip包下载

解压，进入bin目录 创建logstash.conf 并配置：
```xml
input {
    tcp {
    ##host:port就是上面appender中的 destination，这里其实把logstash作为服务，开启9250端口接收logback发出的消息
    host => "127.0.0.1"
    port => 9100
    mode => "server"
    tags => ["tags"]
    codec => json_lines
    }
}
output {
    stdout { codec => rubydebug }
    #输出到es
    #elasticsearch { hosts => "127.0.0.1:9200" }
        #输出到一个文件中
    file {
       path => "D:\logs\test.log"
       codec => line
    }
}

```
我这里先配置输出到文件，后面再修改,创建文件：D:\logs\test.log

启动：

打开cmd（不要使用powershell），进入bin:
```xml
D:\exe\logstash-6.6.1\logstash-6.6.1\bin>logstash -f logstash.conf
```

然后在我们的项目中进行相应的配置：
按这个来：https://github.com/logstash/logstash-logback-encoder

加入pom并指定logback版本：
```xml
<!-- 父pom中 -->
<ch.qos.logback.version>1.2.3</ch.qos.logback.version>

<!--  日志模块-->
<dependency>
  <groupId>net.logstash.logback</groupId>
  <artifactId>logstash-logback-encoder</artifactId>
  <version>5.3</version>
  </dependency>
        <!-- Your project must also directly depend on either logback-classic or logback-access.  For example: -->
  <dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.2.3</version>
  </dependency>
```

配置apppender和logger

```xml
<appender name="stash" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>127.0.0.1:9100</destination>
    <includeCallerData>true</includeCallerData>

    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <includeCallerData>true</includeCallerData>
    </encoder>
  </appender>
  <logger name="logstash" level="info">
      <appender-ref ref="stash"/>
  </logger>
```
测试：
```java
RestController
@RequestMapping("/public/log")
public class LogTestController {
    private static final Logger log = LoggerFactory.getLogger("logstash");
    @Autowired
    LoggingEventRepository repository;

    @GetMapping("/")
    public String test(){
        log.info("sssssssssssssss");
        Iterable<LoggingEvent> all = repository.findAll();

        return "sss";

    }
}
```

访问接口，logstash打印信息：

```
[2019-03-09T11:32:56,358][INFO ][logstash.outputs.file    ] Opening file {:path=>"D:/logs/test.log"}
{
                  "host" => "www.xmind.net",
                 "level" => "INFO",
     "caller_class_name" => "com.muggle.poseidon.controller.LogTestController",
            "@timestamp" => 2019-03-09T03:33:03.413Z,
           "logger_name" => "logstash",
              "@version" => "1",
           "thread_name" => "http-nio-8080-exec-9",
               "message" => "sssssssssssssss",
    "caller_line_number" => 22,
                  "port" => 58368,
           "level_value" => 20000,
      "caller_file_name" => "LogTestController.java",
                  "tags" => [
        [0] "tags"
    ],
    "caller_method_name" => "test"
}
```
test.log输出了文件：

```
2019-03-09T03:33:03.413Z www.xmind.net sssssssssssssss
```
接下来只要把输出路径换成ES就可以了，这属于logstash和es的整合，这里先不讲解；重新回归到我们的请求模块：

我希望我的模块，对每次请求都能记录下来（请求日志），并将记录存到数据库或者ES，同时我要对所有接口都进行一个幂等性的保障；保障接口的幂等性有多种方法，比较简单的是数据库做唯一索引或者加拦截器，我这里加了一个拦截器来保障接口幂等和拦截前端数据的重复提交(关于接口幂等性在其他文档中介绍)：
```java
@Slf4j
public class RequestLockInterceptor implements HandlerInterceptor {
    RedisLock redisTool;
    private int expireTime;

    public RequestLockInterceptor(int expireTime, RedislockImpl redisTool) {
        this.expireTime = expireTime;
        this.redisTool = redisTool;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        if("post".equalsIgnoreCase(request.getMethod())){
            String token = request.getParameter("request_key");
            if (token==null||"".equals(token)){
                log.error("请求非法");
//            throw new PoseidonException("请求太频繁",PoseidonProperties.TOO_NUMBER_REQUEST);
                response.setContentType("application/json;charset=UTF-8");
                PrintWriter writer = response.getWriter();
                writer.write("{\"code\":\"5001\",\"msg\":\"请求非法\"}");
                writer.close();
                return false;
            }
            String ipAddr = RequestUtils.getIpAddr(request);
            String lockKey = request.getRequestURI() + "_"  + "_" + token;
            boolean lock = redisTool.lock(lockKey, ipAddr, expireTime);
            if (!lock) {//
                log.error("拦截表单重复提交");
//            throw new PoseidonException("请求太频繁",PoseidonProperties.TOO_NUMBER_REQUEST);
                response.setContentType("application/json;charset=UTF-8");
                PrintWriter writer = response.getWriter();
                writer.write("{\"code\":\"5001\",\"msg\":\"请求太频繁\"}");
                writer.close();
                return false;
            }
        }
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {

    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
//        String requestURI = request.getRequestURI();
//        String lockKey = request.getRequestURI() + "_" + RequestUtils.getIpAddr(request);
//        redisTool.unlock(lockKey,getIpAddr(request));
    }


}

```
项目使用了redis锁（redis锁原理和使用在其他文档中介绍）

对于系统异常，如果是业务的异常，正常处理，如果是系统发生的异常比如空指针，数据库异常等我希望系统能马上通知，以便排查问题，所以我配置邮件异常通知(关于springboot邮件配置其他文档介绍)：

```java

@RestControllerAdvice
@Slf4j
public class RestExceptionHandlerController {
    @Autowired
    EmailService emailService;
    @Value("${admin.email}")
    private String adminEmail;

    @ExceptionHandler(value = {PoseidonException.class})
    public ResultBean poseidonExceptionHandler(PoseidonException e, HttpServletRequest req) {
        return new ResultBean().setMsg(e.getMsg()).setCode(e.getCode());
    }
    @ExceptionHandler(value = {MethodArgumentNotValidException.class})
    public ResultBean MethodArgumentNotValidException(MethodArgumentNotValidException e, HttpServletRequest req) {
        System.out.println(e.getMessage());
        return new ResultBean().setMsg("数据未通过校验").setCode(PoseidonProperties.COMMIT_DATA_ERROR);
    }

    @ExceptionHandler(value = {Exception.class})
    public ResultBean exceptionHandler(Exception e, HttpServletRequest req) {
        log.error("系统异常：" + req.getMethod() + req.getRequestURI(), e);
        try {
//
            EmailBean emailBean = new EmailBean();
            emailBean.setRecipient(adminEmail);
            emailBean.setSubject("poseidon---系统异常");
            emailBean.setContent("系统异常：" + req.getMethod() + req.getRequestURI()+"----"+e.getMessage());
//            改良
            emailService.sendSimpleMail(emailBean);
        } finally {
            return new ResultBean().setMsg("系统异常，请联系管理员").setCode("500");
        }
    }

    @ExceptionHandler(value = {HttpRequestMethodNotSupportedException.class})
    public ResultBean notsupported(Exception e, HttpServletRequest req) {
        return new ResultBean().setMsg("不支持的请求方式").setCode(PoseidonProperties.NOT_SUPPORT_METHOD);
    }
    @ExceptionHandler(value = {NoHandlerFoundException.class})
    public ResultBean notFoundUrl(Exception e, HttpServletRequest req) {
        return new ResultBean().setMsg("请求路径不存在").setCode("404");
    }
}

```


项目架构信得
common 和core模块存在的意义


