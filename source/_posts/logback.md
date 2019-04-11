---
title: ' logback'
date: 2019-03-28 09:44:50
tags:
---


##### 作者：muggle

&emsp;&emsp;之前写过一个logback模块的文章，但由于时间问题，写得比较凌乱；那篇文章完成的功能是记录请求日志，日志存储数据库，整合logstash；本来后续想加上elk的搭建补全成logback+elk+mysql的一个多功能的日志模块，但由于公司赶项目的原因，并且看的人也不是很多，后来就没什么动力写了。

&emsp;&emsp;这次我打算重写那篇文章，把所有未写完的部分都写全；然后尽量简单明了，条理清晰。嫌太麻烦想直接上手用或者想先测试一下的小伙伴可以去我github上的poseidon项目中的poseidon-request模块翻看源码测试；开始正题。

#### logback介绍
Logback是由log4j创始人设计的另一个开源日志系统,官方网站： http://logback.qos.ch。其模块分为：

1. logback-core：其它两个模块的基础模块
2. logback-classic：它是log4j的一个改良版本，同时它完整实现了slf4j API使你可以很方便地更换成其它日志系统如log4j或JDK14 Logging
3. logback-access：访问模块与Servlet容器集成提供通过Http来访问日志的功能

#### logback的使用
&emsp;&emsp;主要介绍在springboot中的使用，springboot中logback的默认配置文件名称为logback-spring.xml，若需要指定xml名称，需在application.properties（application.yml）中配置logging.config=xxxx.xml。在该xml中通过配置一些节点来配置logbcak，想要
