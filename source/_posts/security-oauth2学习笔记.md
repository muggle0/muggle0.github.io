---
title: security-oauth2学习笔记
date: 2019-04-12 10:49:16
tags: security
---
作者：muggle

## oauth2 相关概念

文章参考[理解OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)

### oauth2 角色关系

在oauth2中分为以下几个角色：Resource server、Authorization server、Resource Owner、application。

Resource server:资源服务器

Authorization server:认证服务器

Resource Owner:资源拥有者

application:第三方应用

oauth2的一次请求流程为：

第三方应用获取认证token 向认证服务器认证，认证服务器通过认证后第三方应用便可向资源服务器拿资源；第三方应用的获取资源的范围由资源拥有者授权。

显然由流程可知，oauth2要保证以下几点：
1.token的有效期和更新方式要可控，安全性要好
2.用户授权第三方应用要可以控制授权范围
<!-- more -->

### oauth2的授权方式

第三方应用必须得到用户的授权（authorization grant），才能获得令牌（access token）。OAuth 2.0定义了四种授权方式。

授权码模式（authorization code）
简化模式（implicit）
密码模式（resource owner password credentials）
客户端模式（client credentials

各个模式具体流程略微复杂，这里节省时间不做介绍，想了解的请参看[理解OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)

## spring-security-oauth2原理分析

在oauth2的框架中，其流程是基于security扩展起来的，在原先的流程上最后面加了一个endpoint节点。其认证服务器其实可以看做拥有两套代码，一套是对第三方应用的权限进行管控的代码，一套是对用户权限进行管控的代码。

对应的配置类分别是：`AuthorizationServerConfigurerAdapter` 和`WebSecurityConfigurerAdapter`



### 授权端点一览表

oauth2提供了一系列URL来完成相应的认证授权相关功能，这些URL都是可配置的，下面贴出各url及其功能；

| 授权端点             | /oauth/authorize      |                  |
| -------------------- | --------------------- | ---------------- |
| 令牌端点             | /oauth/token          | 获取一个令牌     |
| 用户确认授权提交端点 | /oauth/confirm_access | 供用户授权第三方 |
| 授权服务错误信息端点 | /oauth/error          |                  |
| 令牌解析端点         | /oauth/check_token    |                  |
| 公钥端点             | /oauth/token_key      |                  |



### 认证服务器配置

认证服务器相关配置继承`AuthorizationServerConfigurerAdapter`重写configure方法实现

```java
public class AuthorizationServerConfigurerAdapter implements AuthorizationServerConfigurer {
    public AuthorizationServerConfigurerAdapter() {
    }

    public void configure(AuthorizationServerSecurityConfigurer security) throws Exception {
    }

    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
    }

    public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
    }
}
```



*ClientDetailsServiceConfigurer* 验证客户端的方式

> 当一个客户端向认证服务器请求认证的时候，我们需要判别这个客户端是否通过认证；ClientDetailsServiceConfigurer提供了三种认证方式 ：
>
> - clients.withClientDetails()：类似于springSecurity的UserDetailService，对应的也有ClientDetailsService 和 ClientDetails；
> 
>- clients.jdbc():传入一个dataSource(detaliService 是自定义service，更加灵活，这个是为基于数据库准备的)；
> 
> - clients.inMemory() 基于内存，也就是在代码里写死

验证参数说明

>从ClientDetails我们就能很清晰的分辨出客户端需要配置哪些参数
>
>clientId:客户端ID
>secret:客户端密钥
>scope:客户受限的范围。如果范围未定义或为空（默认值），则客户端不受范围限制
>
>authorizedGrantTypes:授权客户端使用的授权类型。默认值为空。
>
>authorities：授予客户端的权限（常规Spring Security权限）
>
>如果我们使用的是数据库存储第三方应用的信息，框架替我们提供了建表语句，https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/test/resources/schema.sql  但对于 MYSQL 来说，默认建表语句中主键为 Varchar(256)，这超过了最大的主键长度，可改成 128，并用 BLOB 替换语句中的 LONGVARBINARY 类型

*AuthorizationServerSecurityConfigurer*

>该类共有13个配置相关的方法：
>
>- passwordEncoder():编解码器
>- tokenKeyAccess（）：oauth2授权服务器会提供一个`/oauth/token_key`的url来供资源服务器获取公钥，这个方法就是配置获取公钥的权限范围，它使用的是SpEL表达式且默认不开启，如果你没用到公钥，则不必管他，在[官方文档](<http://projects.spring.io/spring-security-oauth/docs/oauth2.html#resource-server-configuration>) 上使用JwtToken中使用了该方法，如果你用的是JwtToken请注意
>- checkTokenAccess（）：授权服务器提供一个`/oauth/check_token`的url来供资源服务器解码令牌，该方法就是配置权限范围，同样使用的是SpEL表达式且默认不开启
>- sslOnly()：普通HTTP适用于测试，但授权服务器只能在生产中通过SSL使用，调用方法`sslOnly()`则强制使用ssl。
>- getTokenKeyAccess()：就方法名的意思，获得tokenKeyAccess所设置的SpEL表达式
>- getCheckTokenAccess()：获得checkTokenAccess所设置的SpEL表达式
>- accessDeniedHandler()：拒绝访问处理器
>- realm()：默认值为 "oauth2/client",用处未知
>- authenticationEntryPoint()：处理验证失败的
>- 是allowFormAuthenticationForClients： 允许客户端进行表单身份验证，主要是让/oauth/token支持client_id以及client_secret作登录认证
>- addTokenEndpointAuthenticationFilter：添加令牌端点身份验证过滤器
>- tokenEndpointAuthenticationFilters：添加多个过滤器
>- init():初始化方法
>

*AuthorizationServerEndpointsConfigurer*

>该类配置方法太多了，且官方资料不全，在这里只列举几个常用的配置方法
>
>- pathMapping()：修改授权端点一览表的那些URL
>- tokenStore()：生成Token后的存储方式，可以new RedisTokenStore()来使用redis存储
>-  authenticationManager()：用于密码授权的AuthenticationManager。 当采用密码模式的时候，第三方应用直接提供用户的用户名密码，所以这里需要配置AuthenticationManager（AuthenticationManager的作用参考我security配置解析的文章）
>- allowedTokenEndpointRequestMethods()：允许的请求方式

### 补充说明

oauth2中增加了两个很重要的类`TokenEndPoint`类和`AuthorizationEndpoint`类。`AuthorizationEndpoint` 为授权码模式的端点，它在执行流程的最后位置，它会检验用户是否已经登陆，检验第三方用户，检验授权范围，最后生成code重定向到redirect_uri。

`TokenEndPoint`和`AuthorizationEndpoint` `类似，它用于获取token，在返回token时也会做相应的校验

### 认证服务器使用

为便于学习，我们单独搭一个认证服务器并使用它

依赖：

```xml
     <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-oauth2</artifactId>
            <version>2.0.0.RELEASE</version>
        </dependency>
```

配置：

```java
@SpringBootApplication
@EnableAuthorizationServer
public class PoseidonCloudOauthApplication {

    public static void main(String[] args) {
        SpringApplication.run(PoseidonCloudOauthApplication.class, args);
    }

    @Bean
    public WebSecurityConfigurerAdapter webSecurityConfigurerAdapter() {
        return new WebSecurityConfigurerAdapter() {
            @Override
            public void configure(HttpSecurity httpSecurity) throws Exception {
                httpSecurity.formLogin().and().csrf().disable();
            }
        };
    }
}
```

测试用例：

```java
    @Autowired
    private TestRestTemplate restTemplate;
	// 密码模式测试
    @Test
    public void token_password() {
        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "password");
        params.add("username", "admin");
        params.add("password", "admin");
        params.add("scope", "scope1 scope2");
//        第三方应用登陆
        String response = restTemplate.withBasicAuth("clientId", "clientSecret").
//                用户的用户名密码
                postForObject("/oauth/token", params, String.class);
        System.out.println(response);
    }
// 客户端模式
    @Test
    public void token_client() {
        MultiValueMap<String, String> params = new LinkedMultiValueMap<>();
        params.add("grant_type", "client_credentials");
        String response = restTemplate.withBasicAuth("clientId", "clientSecret").
                postForObject("/oauth/token", params, String.class);
        System.out.println(response);
    }
```

授权码模式要通过测试工具来测；

这里涉及到一个`BasicAuth`的概念，说明一下，其实就是将用户名密码用`username:password` 这样的形式拼接，然后base64编码后得到一个code，在请求头的`Authorization` 中添加 `Basic code`。而postman也支持`BasicAuth`,测试细节略。

## oauth2扩展

