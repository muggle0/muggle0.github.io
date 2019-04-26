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
>- clients.jdbc():传入一个dataSource(搞不懂，既然有withClientDetails了，为啥还来个这个)；
> 
> - clients.inMemory() 基于内存，也就是在代码里写死

验证参数说明

>从ClientDetails我们就能很清晰的分辨出客户端需要配置哪些参数
>
>```java
>public class MyClientDetail  implements ClientDetails {
>@Override
>public String getClientId() {
>   return null;
>}
>
>@Override
>public Set<String> getResourceIds() {
>   return null;
>}
>
>@Override
>public boolean isSecretRequired() {
>   return false;
>}
>
>@Override
>public String getClientSecret() {
>   return null;
>}
>
>@Override
>public boolean isScoped() {
>   return false;
>}
>
>@Override
>public Set<String> getScope() {
>   return null;
>}
>
>@Override
>public Set<String> getAuthorizedGrantTypes() {
>   return null;
>}
>
>@Override
>public Set<String> getRegisteredRedirectUri() {
>   return null;
>}
>
>@Override
>public Collection<GrantedAuthority> getAuthorities() {
>   return null;
>}
>
>@Override
>public Integer getAccessTokenValiditySeconds() {
>   return null;
>}
>
>@Override
>public Integer getRefreshTokenValiditySeconds() {
>   return null;
>}
>
>@Override
>public boolean isAutoApprove(String s) {
>   return false;
>}
>
>@Override
>public Map<String, Object> getAdditionalInformation() {
>   return null;
>}
>}
>```
>clientId:客户端ID
>
>secret:客户端密钥
>
>scope:客户受限的范围。如果范围未定义或为空（默认值），则客户端不受范围限制
>
>authorizedGrantTypes:授权客户端使用的授权类型。默认值为空。
>
>authorities：授予客户端的权限（常规Spring Security权限）

*AuthorizationServerSecurityConfigurer*

>该类共有13个配置相关的方法：
>
>- passwordEncoder():通过源码猜测springSecurity中一样，用于编解码secret，未验证，官网也未发现资料
>- tokenKeyAccess（）：oauth2授权服务器会提供一个`/oauth/token_key`的url来供资源服务器获取公钥，这个方法就是配置获取公钥的权限范围，它使用的是SpEL表达式且默认不开启，如果你没用到公钥，则不必管他，在[官方文档](<http://projects.spring.io/spring-security-oauth/docs/oauth2.html#resource-server-configuration>) 上使用JwtToken中使用了该方法，如果你用的是JwtToken请注意
>- checkTokenAccess（）：授权服务器提供一个`/oauth/check_token`的url来供资源服务器解码令牌，该方法就是配置权限范围，同样使用的是SpEL表达式且默认不开启
>- sslOnly()：普通HTTP适用于测试，但授权服务器只能在生产中通过SSL使用，调用方法`sslOnly()`则强制使用ssl。
>- getTokenKeyAccess()：就方法名的意思，获得tokenKeyAccess所设置的SpEL表达式
>- getCheckTokenAccess()：同上
>- accessDeniedHandler()：拒绝访问处理器，猜测和springSecurity中类似，未验证
>- realm()：默认值为 "oauth2/client",用处未知
>- authenticationEntryPoint():在springSecurity中是处理验证失败的，这里同样未做验证
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
>-  authenticationManager()：身份验证管理器，参考springSecurity中的 authenticationManager
>- allowedTokenEndpointRequestMethods()：允许的请求方式

### 认证服务器使用

为便于学习，我们单独搭一个认证服务器并使用它

