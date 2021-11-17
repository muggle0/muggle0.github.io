---
title: spring笔记
date: 2019-05-08 17:54:00
tags: spring
---

分为20个模块

core container

core beans context expression language

![image.png](https://upload-images.jianshu.io/upload_images/13612520-f726082d79be3e72.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![image.png](https://upload-images.jianshu.io/upload_images/13612520-16a1a229cda57201.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


spring

1. 读取bean的配置信息
2. 根据配置信息实例化一个bean
3. 调用实例化后的实例

beanFactory

bean被当做一种资源，各个factory完成对bean的增删改查，注入读取，初始化等功能

inputStreamSource 封装inputstream

factoryBean :

spring的标准实例化bean的流程是在xml中提供配置信息然后读取配置信息。factoryBean通过实现接口的方式实例化bean（java代码配置bean信息）

demo

![image.png](https://upload-images.jianshu.io/upload_images/13612520-ca7b32793a6d88cd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


单例在spring同一个容器中只会被创建一次，后续直接从单例缓存中获取

循环依赖

objectFactory

singletonFactory

1. 检查缓存是否已经加载过
2. 若没加载就记录下来

创建bean

1. classname
2. 检查override
3. 检查bean是否已经存在
4. 创建bean

实例化前置处理器

实例化后置处理器

循环依赖

检查是否循环依赖

循环依赖会导致内存溢出

构造器循环依赖

![image.png](https://upload-images.jianshu.io/upload_images/13612520-3ca9287803145b3f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


支持用户扩展

### SpringMVC流程

1、 用户发送请求至前端控制器DispatcherServlet。

2、 DispatcherServlet收到请求调用HandlerMapping处理器映射器。

3、 处理器映射器找到具体的处理器(可以根据xml配置、注解进行查找)，生成处理器对象及处理器拦截器(如果有则生成)一并返回给DispatcherServlet。

4、 DispatcherServlet调用HandlerAdapter处理器适配器。

5、 HandlerAdapter经过适配调用具体的处理器(Controller，也叫后端控制器)。

6、 Controller执行完成返回ModelAndView。

7、 HandlerAdapter将controller执行结果ModelAndView返回给DispatcherServlet。

8、 DispatcherServlet将ModelAndView传给ViewReslover视图解析器。

9、 ViewReslover解析后返回具体View。

10、DispatcherServlet根据View进行渲染视图（即将模型数据填充至视图中）。

11、 DispatcherServlet响应用户。

**组件：**  **1、前端控制器DispatcherServlet（不需要工程师开发）,由框架提供**  作用：接收请求，响应结果，相当于转发器，中央处理器。有了dispatcherServlet减少了其它组件之间的耦合度。  用户请求到达前端控制器，它就相当于mvc模式中的c，dispatcherServlet是整个流程控制的中心，由它调用其它组件处理用户的请求，dispatcherServlet的存在降低了组件之间的耦合性。

**2、处理器映射器HandlerMapping(不需要工程师开发),由框架提供**  作用：根据请求的url查找Handler  HandlerMapping负责根据用户请求找到Handler即处理器，springmvc提供了不同的映射器实现不同的映射方式，例如：配置文件方式，实现接口方式，注解方式等。

**3、处理器适配器HandlerAdapter**  作用：按照特定规则（HandlerAdapter要求的规则）去执行Handler  通过HandlerAdapter对处理器进行执行，这是适配器模式的应用，通过扩展适配器可以对更多类型的处理器进行执行。

**4、处理器Handler(需要工程师开发)**  **注意：编写Handler时按照HandlerAdapter的要求去做，这样适配器才可以去正确执行Handler**  Handler 是继DispatcherServlet前端控制器的后端控制器，在DispatcherServlet的控制下Handler对具体的用户请求进行处理。  由于Handler涉及到具体的用户业务请求，所以一般情况需要工程师根据业务需求开发Handler。

**5、视图解析器View resolver(不需要工程师开发),由框架提供**  作用：进行视图解析，根据逻辑视图名解析成真正的视图（view）  View Resolver负责将处理结果生成View视图，View Resolver首先根据逻辑视图名解析成物理视图名即具体的页面地址，再生成View视图对象，最后对View进行渲染将处理结果通过页面展示给用户。 springmvc框架提供了很多的View视图类型，包括：jstlView、freemarkerView、pdfView等。  一般情况下需要通过页面标签或页面模版技术将模型数据通过页面展示给用户，需要由工程师根据业务需求开发具体的页面。

**6、视图View(需要工程师开发jsp...)**  View是一个接口，实现类支持不同的View类型（jsp、freemarker、pdf...）

**核心架构的具体流程步骤如下：**  1、首先用户发送请求——>DispatcherServlet，前端控制器收到请求后自己不进行处理，而是委托给其他的解析器进行处理，作为统一访问点，进行全局的流程控制；  2、DispatcherServlet——>HandlerMapping， HandlerMapping 将会把请求映射为HandlerExecutionChain 对象（包含一个Handler 处理器（页面控制器）对象、多个HandlerInterceptor 拦截器）对象，通过这种策略模式，很容易添加新的映射策略；  3、DispatcherServlet——>HandlerAdapter，HandlerAdapter 将会把处理器包装为适配器，从而支持多种类型的处理器，即适配器设计模式的应用，从而很容易支持很多类型的处理器；  4、HandlerAdapter——>处理器功能处理方法的调用，HandlerAdapter 将会根据适配的结果调用真正的处理器的功能处理方法，完成功能处理；并返回一个ModelAndView 对象（包含模型数据、逻辑视图名）；  5、ModelAndView的逻辑视图名——> ViewResolver， ViewResolver 将把逻辑视图名解析为具体的View，通过这种策略模式，很容易更换其他视图技术；  6、View——>渲染，View会根据传进来的Model模型数据进行渲染，此处的Model实际是一个Map数据结构，因此很容易支持其他视图技术；  7、返回控制权给DispatcherServlet，由DispatcherServlet返回响应给用户，到此一个流程结束。

下边两个组件通常情况下需要开发：

Handler：处理器，即后端控制器用controller表示。

View：视图，即展示给用户的界面，视图中通常需要标签语言展示模型数据。

WebApplicationContext

ServletContext

ApplicationContext

问：

我们可以通过

ApplicationContext ap = new ClassPathXmlApplicationContext("applicationContext.xml");

得到一个spring容器，那么在传统ssm项目中是如何。。知道了

## spring bean的生命周期

实例化bean对象(通过构造方法或者工厂方法)

设置对象属性(setter等)（依赖注入）

如果Bean实现了BeanNameAware接口，工厂调用Bean的setBeanName()方法传递Bean的ID。（和下面的一条均属于检查Aware接口）

如果Bean实现了BeanFactoryAware接口，工厂调用setBeanFactory()方法传入工厂自身

将Bean实例传递给Bean的前置处理器的postProcessBeforeInitialization(Object bean, String beanname)方法

调用Bean的初始化方法

将Bean实例传递给Bean的后置处理器的postProcessAfterInitialization(Object bean, String beanname)方法

使用Bean

容器关闭之前，调用Bean的销毁方法

