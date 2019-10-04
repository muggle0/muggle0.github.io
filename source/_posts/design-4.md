---
title: 设计模式-适配器
date: 2019-07-18 20:19:34
tags: 设计模式
---



适配器模式(Adapter Pattern) ：将一个接口转换成客户希望的另一个接口，适配器模式使接口不兼容的那些类可以一起工作，其别名为包装器(Wrapper)。适配器模式既可以作为类结构型模式，也可以作为对象结构型模式。

## 模式结构

适配器模式包含如下角色：

- Target：目标抽象类
- Adapter：适配器类
- Adaptee：适配者类
- Client：客户类

<!--more-->

## 源码导读

我们都知道springMVC就用到了适配器模式，那他是怎么适配呢，我们来看看它的源码，首先我们要清楚springMVC的执行原理，它的整个流程我这里就不像述了，说一下关键的部分：

1. `DispatcherServlte`会根据配置文件信息注册`HandlerAdapter`，如果在配置文件中没有配置，那么`DispatcherServlte`会获取`HandlerAdapter`的默认配置，如果是读取默认配置的话，`DispatcherServlte`会读取`DispatcherServlte.properties`文件,该文件中配置了三种`HandlerAdapter`：`HttpRequestHandlerAdapter`，`SimpleControllerHandlerAdapter`和`AnnotationMethodHandlerAdapter`。`DispatcherServlte`会将这三个`HandlerAdapter`对象存储到它的`handlerAdapters`这个集合属性中，这样就完成了`HandlerAdapter`的注册。
2. `DispatcherServlte`会根据`handlerMapping`传过来的`controller`与已经注册好了的`HandlerAdapter`一一匹配，看哪一种`HandlerAdapter`是支持该controller类型的，如果找到了其中一种`HandlerAdapter`是支持传过来的`controller`类型，那么该`HandlerAdapter`会调用自己的handle方法，handle方法运用java的反射机制执行controller的具体方法来获得`ModelAndView`

`DispatcherServlte`部分源码

```java
public class DispatcherServlet extends FrameworkServlet {
    ......
    ......
    @Nullable
    private List<HandlerMapping> handlerMappings;
    @Nullable
    private List<HandlerAdapter> handlerAdapters;
 	protected void doDispatch(HttpServletRequest request, HttpServletResponse response) throws Exception {
        HttpServletRequest processedRequest = request;
        HandlerExecutionChain mappedHandler = null;
        boolean multipartRequestParsed = false;
        WebAsyncManager asyncManager = WebAsyncUtils.getAsyncManager(request);

        try {
            try {
                ModelAndView mv = null;
                Object dispatchException = null;

                try {
                    ......
                    ......

                    HandlerAdapter ha = this.getHandlerAdapter(mappedHandler.getHandler());
                    ......
                    ......

                    mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
                    if (asyncManager.isConcurrentHandlingStarted()) {
                        return;
                    }

                    this.applyDefaultViewName(processedRequest, mv);
                    mappedHandler.applyPostHandle(processedRequest, response, mv);
                } catch (Exception var20) {
                    dispatchException = var20;
                } catch (Throwable var21) {
				......
                }
			......
            } catch (Exception var22) {
               ......
            } catch (Throwable var23) {
 			  ......
            }

        } finally {
            ......
            ......
        }
    }
}
```

这里只放上比较关键的代码，我们可以看到当一个请求进入`doDispatch()`方法的时候，它先去`getHandlerAdapter()`中拿到适配器，这就是第二步中根据`handlerMapping`中的`controller`找到对应适配器。找到适配器后通过`ha.handle(processedRequest, response, mappedHandler.getHandler())`执行我们自己的`controller`，`mappedHandler.getHandler()`就是我们自己的`controller`。

至于`handler()`如何知道该去执行controller中哪个方法，当然是通过注解去转换对应方法的。因此，这里的适配器模式还不是特别的纯粹，还结合了反射机制。`DispatcherServlte`属于客户端，我们的`Controller`属于被适配的类，`HandlerAdapter`属于适配器。

现在我们假定需要写一个线程池任务调度框架，我们知道JDK自带的线程框架可以创建一个线程池，但是线程池只能传入实现`runnable`接口或者`callable`接口的对象。

```java
ExecutorService cachedThreadPool = Executors.newCachedThreadPool();
cachedThreadPool.execute(new Runnable() {
    @Override
     public void run() {
     }
})
```

那我们要咋样可以让客户端使用的时候无须继承`runnable`来使用我们的这个框架呢。你可以像springMVC一样使用适配器加注解。也可以提供一个实现`Runnable`接口的抽象适配器类，让客户端进行一定的配置来将普通的类适配到`Runnable`。

关于适配器的使用方面还有很多，比如`spring security`的`WebSecurityConfigurerAdapter`和`netty`中的`ChannelInboundHandlerAdapter` 对于适配器模式类名一般都以`Adapter`结尾

