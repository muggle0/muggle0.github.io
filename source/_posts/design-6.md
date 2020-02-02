---
title: 设计模式—门面模式
date: 2020-02-02 17:29:30
tags: 设计模式
---

门面（Facade）模式的定义：是一种通过为多个复杂的子系统提供一个一致的接口，而使这些子系统更加容易被访问的模式。该模式对外有一个统一接口，外部应用程序不用关心内部子系统的具体的细节，这样会大大降低应用程序的复杂度，提高了程序的可维护性。

门面模式又被称作外观模式，这个模式特点很鲜明，在生活中我们就能找到不少例子。比如110，我们生活中遇到困难或者危险等一系列问题，我们都是直接打110找警察同志，然后由公安局统一处理，对应不同的情况再细化到公安的各个部门去处理。



## 模式结构

门面模式是“迪米特法则”的应用，它的优点：

1. 降低了子系统与客户端之间的耦合度，使得子系统的变化不会影响调用它的客户类。
2. 对客户屏蔽了子系统组件，减少了客户处理的对象数目，并使得子系统使用起来更加容易。
3. 降低了大型软件系统中的编译依赖性，简化了系统在不同平台之间的移植过程，因为编译一个子系统不会影响其他的子系统，也不会影响外观对象。

门面模式的缺点：

1. 不能很好地限制客户使用子系统类。
2. 增加新的子系统可能需要修改外观类或客户端的源代码，违背了“开闭原则”。

它的结构如下：

1. 外观（Facade）角色：为多个子系统对外提供一个共同的接口。
2. 子系统（Sub System）角色：实现系统的部分功能，客户可以通过外观角色访问它。
3. 客户端：通过一个外观角色访问各个子系统的功能。

## 源码导读

在 `servlet` 中 `httprequest` 使用的便是门面模式；我们想要 获得请求信息或者是使用请求的一些功能的时候，我们只需要找`HttpServletRequest` 这个接口就行，这个接口提供了获取请求头信息，请求方式，Context等信息：

```
public interface HttpServletRequest extends ServletRequest {
    String BASIC_AUTH = "BASIC";
    String FORM_AUTH = "FORM";
    String CLIENT_CERT_AUTH = "CLIENT_CERT";
    String DIGEST_AUTH = "DIGEST";

    String getAuthType();

    Cookie[] getCookies();

    long getDateHeader(String var1);

    String getHeader(String var1);

    Enumeration getHeaders(String var1);

    Enumeration getHeaderNames();

    int getIntHeader(String var1);

    String getMethod();

    String getPathInfo();

    String getPathTranslated();

    String getContextPath();

    String getQueryString();

    String getRemoteUser();

    boolean isUserInRole(String var1);

    Principal getUserPrincipal();

    String getRequestedSessionId();

    String getRequestURI();

    StringBuffer getRequestURL();

    String getServletPath();

    HttpSession getSession(boolean var1);

    HttpSession getSession();

    boolean isRequestedSessionIdValid();

    boolean isRequestedSessionIdFromCookie();

    boolean isRequestedSessionIdFromURL();

    /** @deprecated */
    boolean isRequestedSessionIdFromUrl();
}
```

而其实现类 `RequestFacade` 就是web封装的门面实现类：

```
public class RequestFacade implements HttpServletRequest {
     protected Request request = null;
    protected static final StringManager sm = StringManager.getManager(RequestFacade.class);
    ...
}
```

当我们想要请求信息的时候就不必在取找其他类，第一时间想到的是从 `HttpServletRequest` 中获取。

外观模式的使用场景：

- 分层结构系统构建时，使用外观模式定义子系统中每层的入口点可以简化子系统之间的依赖关系。
- 外观模式可以屏蔽系统的复杂性，对外提供统一接口。
- 当客户端依赖多个子系统时，提供一个门面可分离这种依赖性。