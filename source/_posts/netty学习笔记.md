---
title: ' netty学习笔记第一篇'
date: 2019-04-01 18:02:04
tags: netty
---

作者：muggle

netty框架代码很猛（读源码有益身心健康），学习起来也比较难；在阅读这篇文章我假设你有了一定nio基础，tcp网络协议基础，否则不建议阅读。

关于netty的学习视频我推荐B站张龙的教学视频，讲的很不错。学netty之前先学会用，然后在去看他的原理这样学起来会轻松不少。

<!--more-->

### http demo

用netty实现一个http服务端

编写main函数

```java
public class TestNetty {
    public static void main(String[] args) throws InterruptedException {
//        事件循环组 接收连接，将连接发送给work
        NioEventLoopGroup bossGroup = new NioEventLoopGroup();
//        work 干活
        NioEventLoopGroup workerGroup = new NioEventLoopGroup();
//      简化服务端启动
        ServerBootstrap serverBootstrap=new ServerBootstrap();
//                     打开通道                                               子处理器 服务端初始化器
  serverBootstrap.group(bossGroup,workerGroup).channel(NioServerSocketChannel.class).childHandler(new TestServerInitlizer());、
      // 绑定接口
        final ChannelFuture sync = serverBootstrap.bind(8081).sync();
        sync.channel().closeFuture().sync();
        bossGroup.shutdownGracefully();
        workerGroup.shutdownGracefully();
    }
}

```

编写初始化器

```java
// 初始化器 channel注册好之后 自动创建 执行代码
public class TestServerInitlizer extends ChannelInitializer<SocketChannel> {
    @Override
    protected void initChannel(SocketChannel socketChannel) throws Exception {
        final ChannelPipeline pipeline = socketChannel.pipeline();
//        对web响应编解码
        pipeline.addLast("httpserverCodec",new HttpServerCodec());
//        起名加入管道  自己的处理器
        pipeline.addLast("testHttpResponse",new TestHttpServerHandler());
    }
}
```

编写数据处理器

```java
public class TestHttpServerHandler extends SimpleChannelInboundHandler<HttpObject> {
//    构造一个Http响应
    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, HttpObject httpObject) throws Exception {
        System.out.println("请求读取处理4");
        ByteBuf buffer=Unpooled.copiedBuffer("<!DOCTYPE html>\n" +
                "<html lang=\"en\">\n" +
                "<head>\n" +
                "    <meta charset=\"UTF-8\">\n" +
                "    <title>Title</title>\n" +
                "</head>\n" +
                "<body>\n" +
                "<h1>这是一个Netty构造的http响应</h1>\n" +
                "</body>\n" +
                "</html>", CharsetUtil.UTF_8);
        FullHttpResponse response=new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,HttpResponseStatus.OK,buffer);
        response.headers().set(HttpHeaderNames.CONTENT_TYPE,"text/html");
        response.headers().set(HttpHeaderNames.CONTENT_LENGTH,buffer.readableBytes());
        channelHandlerContext.writeAndFlush(response);
       channelHandlerContext.close();
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("通道处于活动状态 3");
        super.channelActive(ctx);
    }

    @Override
    public void channelRegistered(ChannelHandlerContext ctx) throws Exception {
        System.out.println("通道注册 2");
        super.channelRegistered(ctx);
    }

    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        System.out.println("处理器添加 1");
        super.handlerAdded(ctx);
    }
    @Override
    public void channelInactive(ChannelHandlerContext ctx) throws Exception {
        System.out.println("通道数据进入5");
        super.channelInactive(ctx);
    }

    @Override
    public void channelUnregistered(ChannelHandlerContext ctx) throws Exception {
        System.out.println("通道取消注册6");
        super.channelUnregistered(ctx);
    }
}
```

说明：

我们来看一下构造一个http服务端，都需要干些啥。

在main函数中，我们创建了两个线程组`NioEventLoopGroup`，boss线程组负责接收请求，work线程组负责处理请求。`ServerBootstrap`服务端配置辅助器进行服务端配置，绑定端口号。

初始化器`ChannelInitializer<SocketChannel>`对管道设置各种处理器，数据处理器`SimpleChannelInboundHandler<HttpObject>` 的`channelRead0`方法处理数据，调用`channelHandlerContext.writeAndFlush` 将数据写入通道，其他重写的方法看代码便能知道是干嘛的

### socket demo

socket连接步骤大同小异

编写server的main函数

```java
public static void main(String[] args) {
        EventLoopGroup boss=new NioEventLoopGroup();
        NioEventLoopGroup worker = new NioEventLoopGroup();
        try {
            ServerBootstrap serverBootstrap = new ServerBootstrap();
            serverBootstrap.group(boss,worker).channel(NioServerSocketChannel.class).childHandler(new MyServerInitializer());
            ChannelFuture sync = serverBootstrap.bind(8081).sync();
            sync.channel().closeFuture().sync();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            boss.shutdownGracefully();
            worker.shutdownGracefully();
        }
    }
```

编写初始化器

```java
public class MyServerInitializer extends ChannelInitializer<SocketChannel> {
    @Override
    protected void initChannel(SocketChannel socketChannel) throws Exception {
        ChannelPipeline pipeline = socketChannel.pipeline();
//        jia 一堆处理器 策略模式
        pipeline.addLast(new LengthFieldBasedFrameDecoder(Integer.MAX_VALUE,0,4,0,4));
        pipeline.addLast(new LengthFieldPrepender(4));
        pipeline.addLast(new StringDecoder(CharsetUtil.UTF_8));
        pipeline.addLast(new StringEncoder(CharsetUtil.UTF_8));
        pipeline.addLast(new MyserverHandler());
    }
}
```

编写数据处理器

```jav

public class MyserverHandler extends SimpleChannelInboundHandler<String> {
    private static ChannelGroup group=new DefaultChannelGroup(GlobalEventExecutor.INSTANCE);
//    处理方法
    protected void channelRead0(ChannelHandlerContext ctx, String s) throws Exception {
        Channel channel = ctx.channel();
        group.writeAndFlush(ctx.channel().remoteAddress()+">>>>"+s);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();

        ctx.close();
    }

    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        Channel channel = ctx.channel();
        group.writeAndFlush(channel.remoteAddress()+"连接地址》》》》》》》");
        group.add(channel);
    }

    @Override
    public void handlerRemoved(ChannelHandlerContext ctx) throws Exception {
        Channel channel = ctx.channel();
        group.writeAndFlush(channel.remoteAddress()+"断开连接》》》》》》》");
    }
}
```

编写client 的main

```java
 public static void main(String[] args) {
        EventLoopGroup boss = new NioEventLoopGroup();
        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap.group(boss).channel(NioSocketChannel.class).handler(new MyClientInitializer());
            ChannelFuture sync = bootstrap.connect("127.0.0.1",8081).sync();
            Channel channel = sync.channel();
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
            while (true){
                channel.writeAndFlush(bufferedReader.readLine());
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            boss.shutdownGracefully();
        }
    }
```

其他和服务端一样，所以略；

服务端启动类`serverBootstrap.bind(8081).sync()` 而客户端启动类配置是` ChannelFuture sync = bootstrap.connect("127.0.0.1",8081).sync();`区别就在这里

### websocket demo

[github](<https://github.com/muggle0/learn/tree/all>) netty模块 下有所有代码

