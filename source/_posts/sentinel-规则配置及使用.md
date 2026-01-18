---
title: sentinel 规则配置及使用
date: 2021-12-19 16:35:33
tags: 中间件
---

sentinel 增加规则的方式 包括三种，数据源加载，代码加载，控制台加载；每一类流控规则我都会从这三个方面去说明如何使用。
<!-- more -->
## 流量控制

流量控制是通过监控应用流量的qps或者并发线程数是否达到阈值来保护应用的一种手段，避免应用被瞬时的流量高峰冲垮，从而保障系统的高可用。

流量控制的方式：

- 并发线程数流控：通过控制并发线程数来保证访问资源的流量不超过某个阈值
- qps流控：通过控制资源的qps来达到流控的目的，qps相比较于并发线程数流控效果更为直观。

流量控制的相关概念：

- resource：资源名称，资源可以是一个代码块或者方法
- count: 限流阈值
- grade: 限流阈值类型
- limitApp: 流控针对的调用来源，若为default则不区划来源，在分布式系统中该参数有用
- strategy: 限流策略
- controlBehavior: 流控行为，包括直接拒绝，warm up ,排队等待。直接拒接就是超出阈值，直接拒绝后面的请求；warm up 是让系统预热一段时间，
它的阈值并不是一开始就是设定值，会随着qps 或线程数的增加而慢慢提高到设定值；排队等待是请求过多时，让请求匀速的进入后台进行处理。采用漏斗算法，
控制流量设置超时时间，超时的则将请求抛弃，返回错误信息

流控规则代码方式配置示例：

```java

        FlowRule rule1 = new FlowRule();
        rule1.setResource("test.hello");
        rule1.setGrade(RuleConstant.FLOW_GRADE_QPS);
        // 每秒调用最大次数为 1 次
        rule1.setCount(1);
        List<FlowRule> rules = new ArrayList<>();
        // 将控制规则载入到 Sentinel
        FlowRuleManager.loadRules(rules);
```

流控规则控制台配置示例：

![](/images/sentinel2.jpg)

流控规则数据源json示例：


```json
[{"clusterConfig":{"acquireRefuseStrategy":0,"clientOfflineTime":2000,"fallbackToLocalWhenFail":true,"resourceTimeout":2000,"resourceTimeoutStrategy":0,"sampleCount":10,"strategy":0,"thresholdType":0,"windowIntervalMs":1000},"clusterMode":false,"controlBehavior":0,"count":1.0,"grade":1,"limitApp":"default","maxQueueingTimeMs":500,"resource":"test","strategy":0,"warmUpPeriodSec":10}]
```

## 降级规则

熔断降级会在调用链路中当某个资源指数超出阈值时对这个资源的调用进行熔断，在熔断时间窗口内所有调用都快速失败调用降级方法，直到熔断恢复；
降级熔断和流控规则的区别是在超出阈值后的时间窗内所有的调用都会被降级，直到熔断恢复。

熔断降级相关概念：

- resource：资源名称，资源可以是一个代码块或者方法 
- count: 熔断阈值
- grade: 熔断阈值类型(秒级RT/秒级异常比例/分钟级异常数)
- timeWindow: 降级的时间，单位秒
- rtSlowRequestAmount: RT模式下1秒内连续多少个请求的平均RT超出阈值才能触发熔断
- minRequestAmount: 异常熔断触发的最小请求数，请求数小于该值时即使异常比例超过阈值也不会熔断



熔断降级策略：

- 秒级RT（默认）：在1秒内进入的n个响应中，如果最终的平均响应时间超过了阈值，那么在接下来的timeWindow 时间内会自动熔断降级接下来的响应。
- 秒级异常比例：当每秒请求数超过n个，且异常请求的比例超过阈值，那么在接下来的timeWindow 时间内会自动熔断降级接下来的响应。
- 分钟级异常数：当一分钟内请求的数量超过阈值后会熔断，因为统计时长是一分钟，当timeWindow降级熔断时间小于一分钟，当降级熔断结束后可能仍超过异常阈值继续进入熔断降级状态

降级熔断代码配置
```java
    DegradeRule rule = new DegradeRule();
    List<DegradeRule> rules1=new ArrayList<>();
    //资源名称
    rule.setResource("test.hello");
    // 熔断平均响应时间阈值
    rule.setCount(0.01);
    // 秒级RT
    rule.setGrade(RuleConstant.DEGRADE_GRADE_RT);
    rule.setTimeWindow(10);
    rules1.add(rule);
    DegradeRuleManager.loadRules(rules1);
```

流控规则控制台配置示例：

![](/images/降级规则.png)
## 热点规则

热点规则是对热点数据进行限流，支持对特定参数和参数的值限流。热点限流会统计参数中的热点参数，并根据配置的限流阈值与模式对包含热点参数的资源进行限流。
Sentinel利用LRU策略统计最近最常访问的热点参数，结合令牌桶算法来进行参数级别的流控。

热点规则的概念：

- resource：资源名称，资源可以是一个代码块或者方法 
- count: 熔断阈值
- grade: 熔断阈值类型(秒级RT/秒级异常比例/分钟级异常数)
- durationInSec: 统计窗口时间长度（单位为秒，默认1S） 默认1S
- controlBehavior: 流控效果（支持快速失败和匀速排队模式，默认快速失败）
- maxQueueingTimeMs: 最大排队等待时长（仅在匀速排队模式生效）
- paramIdx: 热点参数的索引，必填，对应 SphU.entry(xxx, args) 中的参数索引位置
- paramFlowItemList: 参数例外项，可以针对指定的参数值单独设置限流阈值，不受前面 count 阈值的限制。仅支持基本类型和字符串类型


热点规则代码配置
```java
    ParamFlowRule paramFlowRule = new ParamFlowRule("resourceName")
            .setParamIdx(0)
            .setCount(5);
    // 单独设置限流 QPS，设置param 参数限流规则
    ParamFlowItem item = new ParamFlowItem().setObject("param")
            .setClassType(int.class.getName())
            .setCount(10);
    paramFlowRule.setParamFlowItemList(Collections.singletonList(item));
    ParamFlowRuleManager.loadRules(Collections.singletonList(paramFlowRule));
```
流控规则控制台配置示例：

![](/images/热点规则.jpg)

## 系统规则

系统规则限流是从整体维度上去进行流控，结合应用的load,cpu使用率,总体平均RT,入口QPS和并发线程数等几个维度的监控指标来对总体的流量进行限流，在系统稳定的前提下保证系统的吞吐量

系统规则模式：

- load 自适应: 当系统负载高于某个阈值，就禁止或者减少流量的进入，当load 开始好转，则恢复流量的进入，通过读取操作系统参数 load1 来判断，仅对类unix系统生效。
- cpu 使用率: 当cpu 使用率超过阈值开始限流
- 平均RT: 当系统平均响应时间超过阈值开始限流
- 并发线程数: 当并发线程数超过阈值开始限流
- 入口qps: 当系统入口qps超过阈值开始限流

系统规则的概念

- highestSystemLoad: 负载触发值
- avgRt: 平均响应时间
- qps: 应用入口qps
- highestCpuUsage: cpu使用率

系统规则配置代码示例：

因为系统规则只对入口规则进行限定,所以需要将资源通过注解配置 `@SentinelResource(entryType = EntryType.IN)` 来指定为入口资源

```java
    // 指定资源为入口资源
    @GetMapping("/test3")
    @SentinelResource(entryType = EntryType.IN)
    public String test3(){
        return ">>>>>>>>";
    }

    SystemRule systemRule = new SystemRule();
    systemRule.setHighestCpuUsage(0.8);
    systemRule.setAvgRt(10);  
    systemRule.setQps(10);   
    systemRule.setMaxThread(10);  
    systemRule.setHighestSystemLoad(2.5);   
    SystemRuleManager.loadRules(Collections.singletonList(systemRule));
```
![](/images/系统规则.jpg)

## 授权规则

授权规则的作用是根据调用来源来拦截调用资源的请求，当不符合放行规则的请求过来就会被拒绝掉。

授权规则的概念

- resource: 资源名
- limitApp: 请求来源，对应的黑名单或者白名单；
- qps: 应用入口qps
- strategy: 限制模式，分黑名单模式（authority_black），白名单模式（authority_white 默认）

授权规则代码配置示例：

```java
    AuthorityRule authorityRule = new AuthorityRule();
    authorityRule.setStrategy(RuleConstant.AUTHORITY_BLACK);
    authorityRule.setLimitApp("127.0.0.1");
    authorityRule.setResource("test.hello");
    AuthorityRuleManager.loadRules(Collections.singletonList(authorityRule));
```
这里 limitApp 我设置的是 请求来源的ip 地址，这个ip地址是要我们手动去通过 `ContextUtil.enter(resourceName, origin)` 来设置的。

```java
public class MyInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        ContextUtil.enter("test.hello",  request.getHeader("x-forwarded-for"));
        return true;
    }
}
```
![](/images/授权规则.jpg)

## spring web 拦截适配

前文提到过 `sentinel-spring-webmvc-adapter` 依赖会提供一个将拦截器 `SentinelWebInterceptor`, 源码为：

```java
    protected String getResourceName(HttpServletRequest request) {
        Object resourceNameObject = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        if (resourceNameObject != null && resourceNameObject instanceof String) {
            String resourceName = (String)resourceNameObject;
            UrlCleaner urlCleaner = this.config.getUrlCleaner();
            if (urlCleaner != null) {
                resourceName = urlCleaner.clean(resourceName);
            }

            if (StringUtil.isNotEmpty(resourceName) && this.config.isHttpMethodSpecify()) {
                resourceName = request.getMethod().toUpperCase() + ":" + resourceName;
            }

            return resourceName;
        } else {
            return null;
        }
    }
```

它会解析一个请求为的请求地址为一个资源名，然后在sentinel控制台上就能看到各个请求的流控数据。但它没有提供请求适配各类流控规则的相关代码，
我们想要无缝的通过请求去适配各种流控规则还需要引入依赖：

```xml
        <dependency>
            <groupId>com.alibaba.csp</groupId>
            <artifactId>sentinel-web-servlet</artifactId>
            <version>1.8.1</version>
        </dependency>
```
然后注册一个过滤器：

```java

    @Bean
    public FilterRegistrationBean sentinelFilterRegistration() {
        FilterRegistrationBean<Filter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new CommonFilter());
        registration.addUrlPatterns("/*");
        registration.setName("sentinelFilter");
        registration.setOrder(1);

        return registration;
    }
```
接入 filter 之后，所有访问的 Web URL 就会被自动统计为 Sentinel 的资源，可以针对单个 URL 维度进行流控。
若希望区分不同 HTTP Method，可以调用 `CommonFilter.init(FilterConfig filterConfig)` 方法将 HTTP_METHOD_SPECIFY 这个 init parameter 设为 true，给每个 URL 资源加上前缀，比如 GET:/foo
这个包中一个重要类是 `WebCallbackManager` 许多限流配置都需要使用到这个类的api。

设置限流处理器：

```java
    WebCallbackManager.setUrlBlockHandler((request, response, e) -> {
        PrintWriter writer = response.getWriter();
        writer.println(">>>>");
        writer.close();
    });

```

设置url清洗器：

```java
WebCallbackManager.setUrlCleaner(new UrlCleaner() {
    @Override
    public String clean(String originUrl) {
        if (originUrl == null || originUrl.isEmpty()) {
            return originUrl;
        }
        // 比如将满足 /foo/{id} 的 URL 都归到 /foo/*
        if (originUrl.startsWith("/foo/")) {
            return "/foo/*";
        }
        // 不希望统计 *.ico 的资源文件，可以将其转换为 empty string (since 1.6.3)
        if (originUrl.endsWith(".ico")) {
            return "";
        }
        return originUrl;
    }
});
```
设置请求来源名称，通过该配置我们在授权规则中就不需要通过`ContextUtil.enter(resourceName, origin)` 设置，而是通过一个自定义
的`RequestOriginParser` 直接指定请求的来源，也就是授权规则中的 `limitApp`:

```java
    WebCallbackManager.setRequestOriginParser(request -> {
        return request.getHeader("x-forwarded-for");
    });
```
