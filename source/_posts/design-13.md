---
title: 设计模式-责任链模式
date: 2020-02-02 17:39:12
tags: 设计模式
---

责任链（Chain of Responsibility）模式的定义：为了避免请求发送者与多个请求处理者耦合在一起，将所有请求的处理者通过前一对象记住其下一个对象的引用而连成一条链；当有请求发生时，可将请求沿着这条链传递，直到有对象处理它为止。

责任链模式也叫职责链模式。

在责任链模式中，客户只需要将请求发送到责任链上即可，无须关心请求的处理细节和请求的传递过程，所以责任链将请求的发送者和请求的处理者解耦了。

<!--more-->

责任链模式是一种对象行为型模式，其主要优点如下。
降低了对象之间的耦合度。该模式使得一个对象无须知道到底是哪一个对象处理其请求以及链的结构，发送者和接收者也无须拥有对方的明确信息。
增强了系统的可扩展性。可以根据需要增加新的请求处理类，满足开闭原则。
增强了给对象指派职责的灵活性。当工作流程发生变化，可以动态地改变链内的成员或者调动它们的次序，也可动态地新增或者删除责任。
责任链简化了对象之间的连接。每个对象只需保持一个指向其后继者的引用，不需保持其他所有处理者的引用，这避免了使用众多的 if 或者 if···else 语句。
责任分担。每个类只需要处理自己该处理的工作，不该处理的传递给下一个对象完成，明确各类的责任范围，符合类的单一职责原则。

## 模式结构

职责链模式主要包含以下角色：
抽象处理者（Handler）角色：定义一个处理请求的接口，包含抽象处理方法和一个后继连接。
具体处理者（Concrete Handler）角色：实现抽象处理者的处理方法，判断能否处理本次请求，如果可以处理请求则处理，否则将该请求转给它的后继者。
客户类（Client）角色：创建处理链，并向链头的具体处理者对象提交请求，它不关心处理细节和请求的传递过程。

# 源码导读

在`spring security` 中其核心设计模式就是责任链模式；它通过注册过滤器链来实现责任链模式，每个过滤器链都只做一件事。springSecurity的责任链顺序如下

> WebAsyncManagerIntegrationFilter：将Security上下文与Spring Web中用于处理异步请求映射的 WebAsyncManager 进行集成。
>
> SecurityContextPersistenceFilter：在每次请求处理之前将该请求相关的安全上下文信息加载到SecurityContextHolder中，然后在该次请求处理完成之后，将SecurityContextHolder中关于这次请求的信息存储到一个“仓储”中，然后将SecurityContextHolder中的信息清除
> 例如在Session中维护一个用户的安全信息就是这个过滤器处理的。
>
> HeaderWriterFilter：用于将头信息加入响应中
>
> CsrfFilter：用于处理跨站请求伪造
>
> LogoutFilter：用于处理退出登录
>
> UsernamePasswordAuthenticationFilter：用于处理基于表单的登录请求，从表单中获取用户名和密码。默认情况下处理来自“/login”的请求。从表单中获取用户名和密码时，默认使用的表单name值为“username”和“password”，这两个值可以通过设置这个过滤器的usernameParameter 和 passwordParameter 两个参数的值进行修改。
>
> DefaultLoginPageGeneratingFilter：如果没有配置登录页面，那系统初始化时就会配置这个过滤器，并且用于在需要进行登录时生成一个登录表单页面。
>
> BasicAuthenticationFilter：检测和处理http basic认证
>
> RequestCacheAwareFilter：用来处理请求的缓存
>
> SecurityContextHolderAwareRequestFilter：主要是包装请求对象request
>
> AnonymousAuthenticationFilter：检测SecurityContextHolder中是否存在Authentication对象，如果不存在为其提供一个匿名Authentication
>
> SessionManagementFilter：管理session的过滤器
>
> ExceptionTranslationFilter：处理 AccessDeniedException 和 AuthenticationException 异常
>
> FilterSecurityInterceptor：可以看做过滤器链的出口
>
> RememberMeAuthenticationFilter：当用户没有登录而直接访问资源时, 从cookie里找出用户的信息, 如果Spring Security能够识别出用户提供的remember me cookie, 用户将不必填写用户名和密码, 而是直接登录进入系统，该过滤器默认不开启。

而责任链的客户类是`HttpSecurity`,它负责对责任链的创建和管理，它的`addFilterAt(Filter filter, Class atFilter)` 方法可在责任链中添加一个过滤器。
在这个框架中 过滤器作为了`抽象处理者（Handler`的角色，各个具体的过滤器类是`具体处理者（Concrete Handler`角色 `HttpSecueiry`是`客户类`角色。