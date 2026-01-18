---
title: ' springSecurity深度解析'
date: 2019-04-11 21:27:31
tags: security
---
作者：muggle

#### 从一个基础的springsecurity开始，进行代码跟踪分析其原理

springsecurity是一个典型的责任链模式；我们先新建一个springboot项目，进行最基本的springsecurity配置，然后debug;我这里使用的开发工具是idea.建议大家也使用idea来进行日常开发。好了话不多说，开始：
<!-- more -->
第一步

新建springboot项目 maven依赖：
```xml
<dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
```

启动项目，控制台上会输出这样一段字符串：
```java
2019-04-11 09:47:40.388  INFO 16716 --- [           main] .s.s.UserDetailsServiceAutoConfiguration :

Using generated security password: a6d55bc6-49fb-4241-a5ae-527e5e644731

```

<!--more-->
现在我们访问 http://localhost:8080 会自动跳转到 http://localhost:8080/login，并弹出一个登陆页面，用户名输user,密码输上面的字符串： a6d55bc6-49fb-4241-a5ae-527e5e644731，每次字符串都是随机的，要留意你的控制台打印的字符串，登陆成功了，现在我们开始debug,看看一次登陆和一次登陆后访问一次不登陆访问这三种情况security都做了哪些事情。

先写一个接口：
```java

@RestController
public class TestController {
    @GetMapping("test")
    public String test(){
        return "hi 你好啊";
    }
}
```
springsecurity 执行过程是走一条过滤器链，所以我们要先明白，有哪些过滤器，并在过滤器上打上断点追踪，下面贴出各个过滤器名称及作用：

>1、WebAsyncManagerIntegrationFilter
将Security上下文与Spring Web中用于处理异步请求映射的 WebAsyncManager 进行集成。
2、SecurityContextPersistenceFilter
在每次请求处理之前将该请求相关的安全上下文信息加载到SecurityContextHolder中，然后在该次请求处理完成之后，将SecurityContextHolder中关于这次请求的信息存储到一个“仓储”中，然后将SecurityContextHolder中的信息清除
例如在Session中维护一个用户的安全信息就是这个过滤器处理的。
3、HeaderWriterFilter
用于将头信息加入响应中
4、CsrfFilter
用于处理跨站请求伪造
5、LogoutFilter
用于处理退出登录
6、UsernamePasswordAuthenticationFilter
用于处理基于表单的登录请求，从表单中获取用户名和密码。默认情况下处理来自“/login”的请求。
从表单中获取用户名和密码时，默认使用的表单name值为“username”和“password”，这两个值可以通过设置这个过滤器的usernameParameter 和 passwordParameter 两个参数的值进行修改。
7、DefaultLoginPageGeneratingFilter
如果没有配置登录页面，那系统初始化时就会配置这个过滤器，并且用于在需要进行登录时生成一个登录表单页面。
8、BasicAuthenticationFilter
处理请求头信息，DigestAuthenticationFilter
9、RequestCacheAwareFilter
用来处理请求的缓存
10、SecurityContextHolderAwareRequestFilter
11、AnonymousAuthenticationFilter
12、SessionManagementFilter
13、ExceptionTranslationFilter
处理 AccessDeniedException 和 AuthenticationException 异常
14、FilterSecurityInterceptor
AbstractInterceptUrlConfigurer.createFilterSecurityInterceptor
15、RememberMeAuthenticationFilter的作用是, 当用户没有登录而直接访问资源时, 从cookie里找出用户的信息, 如果Spring Security能够识别出用户提供的remember me cookie, 用户将不必填写用户名和密码, 而是直接登录进入系统.

先不管那么多，ctr+alt+shift+t（或者按两下shift） 输入类名找到类，打断点，开始debug

#### springsecurity 的默认登陆url是/login:我们访问一下来捋一捋：
其代码顺序是：
`WebAsyncManagerIntegrationFilter`  -> `SecurityContextPersistenceFilter` -> `HeaderWriterFilter` -> `CsrfFilter` -> `LogoutFilter` -> `DefaultLoginPageGeneratingFilter`

然后浏览器会返回一个登陆页面：
![image.png](https://upload-images.jianshu.io/upload_images/13612520-d6e336c80cbf30c5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
#### 说明：
这其实是发起了一个请求登陆页面的请求，请求首先进入`WebAsyncManagerIntegrationFilter` 这个过滤器做了什么我们不必去关系，它下一个过滤器`SecurityContextPersistenceFilter` 通过request的attribute来上了一次请求锁，并且对SecurityContextHolder进行了管理；而SecurityContextHolder是对用户信息进行管理的一套系统，分为三大类

1. SecurityContextHolder 对用户信息增删改查的操作
 2. SecurityContext 将用户名，权限等封装成该对象
 3. SecurityContextHolderStrategy 用于存储 SecurityContext

默认的SecurityContextHolderStrategy 实现类是ThreadLocalSecurityContextHolderStrategy 它使用了ThreadLocal来存储了用户信息。
下一个过滤器`HeaderWriterFilter`请求和响应封装了一下，用于`CsrfFilter`鉴别csrf攻击 `LogoutFilter`判断是不是登出操作，如果是则不执行下面的过滤器，而执行登出的相关操作，DefaultLoginPageGeneratingFilter生成登录页

我们先输入正确的代码登陆一次

通过跟踪代码发现其执行顺序是：
`WebAsyncManagerIntegrationFilter` -> `SecurityContextPersistenceFilter` -> `HeaderWriterFilter`->`CsrfFilter`-> `LogoutFilter`->`UsernamePasswordAuthenticationFilter`->`WebAsyncManagerIntegrationFilter`->`SecurityContextPersistenceFilter`->`HeaderWriterFilter`->`CsrfFilter`->`LogoutFilter`->`DefaultLoginPageGeneratingFilter`->`BasicAuthenticationFilter`->`RequestCacheAwareFilter`->`SecurityContextHolderAwareRequestFilter`->`AnonymousAuthenticationFilter`->`SessionManagementFilter`->`ExceptionTranslationFilter`->`FilterSecurityInterceptor`->`SecurityContextPersistenceFilter`->`LogoutFilter`->`DefaultLoginPageGeneratingFilter`->`RequestCacheAwareFilter`->`SecurityContextHolderAwareRequestFilter`->`AnonymousAuthenticationFilter`->`SessionManagementFilter`->`ExceptionTranslationFilter`->`FilterSecurityInterceptor`

这一次之所以过滤器链跑这么长是因为，这里可以认为发起了三次请求，第一次请求是登陆，登陆成功后转发到 url 为“/”的接口，而我没有这个接口，发生了重定向到“/error” 而“/error”页面是springboot请求失败的错误页面返回机制。
`WebAsyncManagerIntegrationFilter` -> `SecurityContextPersistenceFilter` -> `HeaderWriterFilter`->`CsrfFilter`-> `LogoutFilter`->`UsernamePasswordAuthenticationFilter` 这一过程登陆请求。

`WebAsyncManagerIntegrationFilter`->`SecurityContextPersistenceFilter`->`HeaderWriterFilter`->`CsrfFilter`->`LogoutFilter`->`DefaultLoginPageGeneratingFilter`->`BasicAuthenticationFilter`->`RequestCacheAwareFilter`->`SecurityContextHolderAwareRequestFilter`->`AnonymousAuthenticationFilter`->`SessionManagementFilter`->`ExceptionTranslationFilter`->`FilterSecurityInterceptor`
这是转发到“/”的过程

`SecurityContextPersistenceFilter`->`LogoutFilter`->`DefaultLoginPageGeneratingFilter`->`RequestCacheAwareFilter`->`SecurityContextHolderAwareRequestFilter`->`AnonymousAuthenticationFilter`->`SessionManagementFilter`->`ExceptionTranslationFilter`->`FilterSecurityInterceptor`
这是重定向到error的过程

接下来访问一下我们的/test接口
看看执行顺序：
`WebAsyncManagerIntegrationFilter`->`SecurityContextPersistenceFilter`->`HeaderWriterFilter`->`CsrfFilter`->`LogoutFilter`->`DefaultLoginPageGeneratingFilter`->`BasicAuthenticationFilter`->`RequestCacheAwareFilter`->`SecurityContextHolderAwareRequestFilter`->`AnonymousAuthenticationFilter`->`SessionManagementFilter`->`ExceptionTranslationFilter`->`FilterSecurityInterceptor`
#### 说明：
BasicAuthenticationFilter就是看你请求头里面有没有basic开头的东西，有的话做一些处理，对我们来说没啥用，不必去关心，RequestCacheAwareFilter对请求和响应做了额外处理 SecurityContextHolderAwareRequestFilter 也是对请求做了一些额外处理，我们同样不去关心它。AnonymousAuthenticationFilter过滤器是当securitycontext为null时填充一个匿名权限，这里被执行的原因因为security未配置完全，后面进一步配置了之后再回来详解。ExceptionTranslationFilter是对鉴权或者登陆异常的处理过滤器，FilterSecurityInterceptor可以看做是过滤器链的出口：
```java
 public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        FilterInvocation fi = new FilterInvocation(request, response, chain);
        this.invoke(fi);
    }
```
这个fi就是请求的url值。

现在我们完善一下security配置，让它复杂一点
实现 GrantedAuthority：
```java
@Data
public class MyGrantedAuthority implements GrantedAuthority {
    private String authority;
}
```
实现UserDetails
```java
@Data
@Accessors(chain = true)
public class MyUserDetail implements UserDetails {

    private List<MyGrantedAuthority> authorities;

    private String password;

    private String username;

    private boolean accountNonExpired;

    private boolean accountNonLocked;

    private boolean credentialsNonExpired;

    private boolean enabled;

}

```

实现UserDetailsService
```java
@Service
public class MyUserDetailService implements UserDetailsService {
    @Override
    public UserDetails loadUserByUsername(String s) throws UsernameNotFoundException {
        List<MyGrantedAuthority> authorities = new ArrayList<>();
        MyGrantedAuthority myGrantedAuthority = new MyGrantedAuthority();
        myGrantedAuthority.setAuthority("ROLE_test");
        BCryptPasswordEncoder bCryptPasswordEncoder = new BCryptPasswordEncoder();
        String test = bCryptPasswordEncoder.encode("test");
        authorities.add(myGrantedAuthority);
        return new MyUserDetail().setAuthorities(authorities).setAccountNonExpired(true)
                .setAccountNonLocked(true).setCredentialsNonExpired(true).setEnabled(true)
                .setPassword(test).setUsername("test");
    }
}
```

重写security适配器WebSecurityConfigurerAdapter：
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Autowired
    MyUserDetailService userDetailService;
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(userDetailService).passwordEncoder(new BCryptPasswordEncoder());
    }
    @Override
    public void configure(WebSecurity web) throws Exception {

        web.ignoring().antMatchers("/resources/**/*.html", "/resources/**/*.js",
                "/resources/**/*.css", "/resources/**/*.txt",
                "/resources/**/*.png", "/**/*.bmp", "/**/*.gif", "/**/*.png", "/**/*.jpg", "/**/*.ico");
//        super.configure(web);
    }

   @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().and().csrf().disable();
    }

}
```
这里比开始又要复杂一点了，我先对相关操作进行说明一下：
先从SecurityConfig说起

重写了三个config方法
1.第一个config涉及到的问题比较深——security的认证鉴权系统；
先说认证的过程，当过滤器跑到usernamepasswordFilter的时候就开始做认证了
#### security认证原理
认证的工作是交给AuthenticationManager去做，AuthenticationManager下有多个认证器 AuthenticationProvider
只要其中一个AuthenticationProvider通过认证就算登陆成功，而且在认证器中抛出异常，无法终止认证流程只是算该认证器未通过。
第一个config就算配置了一个AuthenticationManagerBuilder 这个类会生成一个 AuthenticationManager和DaoAuthenticationProvider认证器，认证调用userdetailservice 的loadUserByUsername方法来和你传入的username passworde做比较，password 是通过BCryptPasswordEncoder来做编码后比较的，这样做是为了提高安全性。

2.第二个config是对静态资源的放行；

3.第三个config 配置了登录页请求路径，登陆认证路径，用户名密码属性，和一个test权限，注意一点：我在config配的是hasRole("test")，我设置的权限是  myGrantedAuthority.setAuthority("ROLE_test");为什么这样弄后面会说。
接下来完善一下，边边角角，写个登陆的HTML,一个登陆页面请求接口:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<form method="post" action="/sign_in">
    用户名：<input type="text" name="username" value="test"><br>
    密码：<input type="text" name="password" value="test"><br>
    <input type="text" name="verification"><br>
    <input type="submit" name="test">
</form>
</body>
</html>
```

```java
@Controller
public class LoginController {
    @GetMapping("/login_page")
    public String loginPage(){
        return "loginPage.html";
    }
}

```
启动项目，访问localhost:8080/test
跳转到了/login_page
![image.png](https://upload-images.jianshu.io/upload_images/13612520-40e8574ede6fdade.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
点登陆，debug看看有什么不同 新增的断点DaoAuthenticationProvider和MyUserDetailService
前面执行顺序还是一样，到SecurityContextHolderAwareRequestFilter的时候我们注意一下
```java
public class SecurityContextHolderAwareRequestFilter extends GenericFilterBean {
    private String rolePrefix = "ROLE_";

```
我们权限设置的前缀就是从这来的 到后面讲投票器的时候再细说。
到UsernamePasswordAuthenticationFilter这个过滤器后 下一步到了DaoAuthenticationProvider验证器，验证器执行的是其父类AbstractUserDetailsAuthenticationProvider的authenticate（）方法同时我们看到MyUserDetailService的loadUserByUsername被调用，最后，认证结束转发到访问前路径/test 重新走过滤器。流程和一开始的简单配置一样，走到FilterSecurityInterceptor的时候进入WebExpressionVoter了投票器；
#### security的投票器：
当过滤器链走到尽头（FilterSecurityInterceptor）下一步就是鉴权了，鉴权功能会交给AccessDecisionManager去处理，而AccessDecisionManager下又有多个投票器，其中WebExpressionVoter是security的一个默认投票器，我们来分析一下这个类：
其有个这样的方法
```java
 public int vote(Authentication authentication, FilterInvocation fi, Collection<ConfigAttribute> attributes)
```
返回int类型，1表示赞成，0表示弃权，-1表示反对。当所有投票器的vote执行结束，如果最终结果小于0表示不通过，
方法的参数说明：
1. FilterInvocation  可获得请求的相关信息，比如请求方式（get post）url 等
2.authentication 是从securitycontext中拿出来的用户信息
3.Collection<ConfigAttribute> 是可以访问该路径的权限集合。也就是前面SecurityContextHolderAwareRequestFilter 查找出来的权限，对于在WebSecurityConfigurerAdapter config方法中的hasRole("test")权限规则并不是直接取权限 test,而是加了前缀rolePrefix（“ROLE_”），这个前缀也是可配置的配置方式：[https://docs.spring.io/spring-security/site/docs/5.0.6.RELEASE/reference/htmlsingle/#appendix-faq-role-prefix](https://docs.spring.io/spring-security/site/docs/5.0.6.RELEASE/reference/htmlsingle/#appendix-faq-role-prefix)


一些基本的知识点交代的差不多了，现在，我进行下一步
#### security魔改
需求：我希望后端能做验证码校验，没通过校验的直接登录失败；
实现方式：security给我们提供了在各个过滤器上追加过滤器的方法，我们在UsernamePasswordAuthenticationFilter追加一个过滤器
```java

public class MyUsernamePasswordAuthenticationFilte extends UsernamePasswordAuthenticationFilter {
    private RedisService redisService;
    private boolean postOnly = true;

    public MyUsernamePasswordAuthenticationFilte(RedisService redisService){
        this.redisService=redisService;
    }

    @Override
    public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) throws AuthenticationException {
        redisService.getcCode(request);
        return super.attemptAuthentication(request,response);
    }
}

```
这里redisService 就是你要弄的验证逻辑，其他代码还是从父类那复制过来，不去动它。
为什么要继承UsernamePasswordAuthenticationFilter 而不是继承AbstractAuthenticationProcessingFilter，这样做的好处是可以少写代码少踩坑。
然后修改config
```java
 @Autowired
 RedisService redisService;

 @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().and().csrf().disable();
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
    }


    MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        return myUsernamePasswordAuthenticationFilte;
    }
```
我在加两个处理器，当我登陆成功或者失败，由我自己弄；
登陆成功处理器
```java
public class MyAuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {

        response.setContentType("application/json;charset=UTF-8");
        final PrintWriter writer = response.getWriter();
        writer.write("{\"code\":\"200\",\"msg\":\"登录成功\"}");
        writer.close();
    }
}

```
登陆失败的处理器
```java
public class MyUrlAuthenticationFailureHandler extends SimpleUrlAuthenticationFailureHandler {
    @Override
    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response, AuthenticationException exception) throws IOException, ServletException {
        response.setContentType("application/json;charset=UTF-8");
        final PrintWriter writer = response.getWriter();
        if(exception.getMessage().equals("坏的凭证")){
            writer.write("{\"code\":\"401\",\"msg\":\"登录失败,用户名或者密码有误\"}");
            writer.close();
        }else {
            writer.write("{\"code\":\"401\",\"msg\":\"登录失败,"+exception.getMessage()+"\"}");
            writer.close();
        }

    }
}

```

#### 说明：
为什么要继承SimpleUrlAuthenticationFailureHandler和SimpleUrlAuthenticationSuccessHandler 而不是实现AuthenticationFailureHandler，还是那句话，为了少写代码少踩坑，我这里是返回json字符串，你也可以弄成重定向啥的，也比较容易。
config再改一下：
```java
 MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        myUsernamePasswordAuthenticationFilte.setAuthenticationFailureHandler(new MyUrlAuthenticationFailureHandler());
        myUsernamePasswordAuthenticationFilte.setAuthenticationSuccessHandler(new MyAuthenticationSuccessHandler());
        myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in");
        return myUsernamePasswordAuthenticationFilte;
    }
```
这里要注意 myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in"); 因为 http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);并不是替换掉UsernamePasswordAuthenticationFilter，而是和你自己添加的过滤器同时存在，security会根据url判断该走哪个过滤器，如果loginProcessingUrl还是“/login”的话走的是UsernamePasswordAuthenticationFilter，这里要留意一下。


现在再加需求，我不仅需要普通登录方式，我想其他登录方式；
实现方式：加多个认证器，每个认证器对应一种登录方式
```java
public class MyAuthenticationProvider  implements AuthenticationProvider {
    private UserDetailsService userDetailsService;
    private BCryptPasswordEncoder bCryptPasswordEncoder;
    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
//       这里写验证逻辑
        return null;
    }

    @Override
    public boolean supports(Class<?> aClass) {
        return false;
    }
}

```
在改SecurityConfig
```java
 @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().and().csrf().disable();
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
    }


    MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        myUsernamePasswordAuthenticationFilte.setAuthenticationFailureHandler(new MyUrlAuthenticationFailureHandler());
        myUsernamePasswordAuthenticationFilte.setAuthenticationSuccessHandler(new MyAuthenticationSuccessHandler());
        myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in");
        myUsernamePasswordAuthenticationFilte.setAuthenticationManager(getAuthenticationManager());
        return myUsernamePasswordAuthenticationFilte;
    }
    MyAuthenticationProvider getMyAuthenticationProvider(){
        MyAuthenticationProvider myAuthenticationProvider = new MyAuthenticationProvider(userDetailService,new BCryptPasswordEncoder());
        return myAuthenticationProvider;
    }
    DaoAuthenticationProvider daoAuthenticationProvider(){
        DaoAuthenticationProvider daoAuthenticationProvider = new DaoAuthenticationProvider();
        daoAuthenticationProvider.setPasswordEncoder(new BCryptPasswordEncoder());
        daoAuthenticationProvider.setUserDetailsService(userDetailService);
        return daoAuthenticationProvider;
    }
    protected AuthenticationManager getAuthenticationManager()  {
        ProviderManager authenticationManager = new ProviderManager(Arrays.asList(getMyAuthenticationProvider(),daoAuthenticationProvider()));
        return authenticationManager;
    }
```
我再加需求：
根据不同的客服端做不同的鉴权策略；
实现方式：加投票器；
```java
public class MyExpressionVoter extends WebExpressionVoter {
    @Override
    public int vote(Authentication authentication, FilterInvocation fi, Collection<ConfigAttribute> attributes) {
//        这里写鉴权逻辑
        return 0;
    }
}

```

再次改动config
```java
 @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().accessDecisionManager(accessDecisionManager()).and().csrf().disable();
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
    }


    MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        myUsernamePasswordAuthenticationFilte.setAuthenticationFailureHandler(new MyUrlAuthenticationFailureHandler());
        myUsernamePasswordAuthenticationFilte.setAuthenticationSuccessHandler(new MyAuthenticationSuccessHandler());
        myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in");
        myUsernamePasswordAuthenticationFilte.setAuthenticationManager(getAuthenticationManager());
        return myUsernamePasswordAuthenticationFilte;
    }
    MyAuthenticationProvider getMyAuthenticationProvider(){
        MyAuthenticationProvider myAuthenticationProvider = new MyAuthenticationProvider(userDetailService,new BCryptPasswordEncoder());
        return myAuthenticationProvider;
    }
    DaoAuthenticationProvider daoAuthenticationProvider(){
        DaoAuthenticationProvider daoAuthenticationProvider = new DaoAuthenticationProvider();
        daoAuthenticationProvider.setPasswordEncoder(new BCryptPasswordEncoder());
        daoAuthenticationProvider.setUserDetailsService(userDetailService);
        return daoAuthenticationProvider;
    }
    protected AuthenticationManager getAuthenticationManager()  {
        ProviderManager authenticationManager = new ProviderManager(Arrays.asList(getMyAuthenticationProvider(),daoAuthenticationProvider()));
        return authenticationManager;
    }

    public AccessDecisionManager accessDecisionManager(){
        List<AccessDecisionVoter<? extends Object>> decisionVoters
                = Arrays.asList(
                new MyExpressionVoter(),
                new WebExpressionVoter(),
                new RoleVoter(),
                new AuthenticatedVoter());
        return new UnanimousBased(decisionVoters);
    }
```
在加两个鉴权失败处理器
```java
public class MyAccessDeniedHandler implements AccessDeniedHandler {
    @Override
    public void handle(HttpServletRequest httpServletRequest, HttpServletResponse response, AccessDeniedException e) throws IOException, ServletException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter writer = response.getWriter();
        writer.write("{\"code\":\"403\",\"msg\":\"没有权限\"}");
        writer.close();
    }
}

```
再加一个登出处理器

```java

public class MyLogoutSuccessHandler implements LogoutSuccessHandler {
    @Override
    public void onLogoutSuccess(HttpServletRequest httpServletRequest, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
        final PrintWriter writer = response.getWriter();

        writer.write("{\"code\":\"200\",\"msg\":\"登出成功\"}");
        writer.close();
    }
}

```
最后修改SecurityConfig，最终模样为
```java

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Autowired
    RedisService redisService;
    @Autowired
    MyUserDetailService userDetailService;
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(userDetailService).passwordEncoder(new BCryptPasswordEncoder());
    }
    @Override
    public void configure(WebSecurity web) throws Exception {

        web.ignoring().antMatchers("/resources/**/*.html", "/resources/**/*.js",
                "/resources/**/*.css", "/resources/**/*.txt",
                "/resources/**/*.png", "/**/*.bmp", "/**/*.gif", "/**/*.png", "/**/*.jpg", "/**/*.ico");
//        super.configure(web);
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().accessDecisionManager(accessDecisionManager())
               .and().logout().logoutSuccessHandler(new MyLogoutSuccessHandler())
               .and().csrf().disable();
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
        http.exceptionHandling().accessDeniedHandler(new MyAccessDeniedHandler());
    }


    MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        myUsernamePasswordAuthenticationFilte.setAuthenticationFailureHandler(new MyUrlAuthenticationFailureHandler());
        myUsernamePasswordAuthenticationFilte.setAuthenticationSuccessHandler(new MyAuthenticationSuccessHandler());
        myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in");
        myUsernamePasswordAuthenticationFilte.setAuthenticationManager(getAuthenticationManager());
        return myUsernamePasswordAuthenticationFilte;
    }
    MyAuthenticationProvider getMyAuthenticationProvider(){
        MyAuthenticationProvider myAuthenticationProvider = new MyAuthenticationProvider(userDetailService,new BCryptPasswordEncoder());
        return myAuthenticationProvider;
    }
    DaoAuthenticationProvider daoAuthenticationProvider(){
        DaoAuthenticationProvider daoAuthenticationProvider = new DaoAuthenticationProvider();
        daoAuthenticationProvider.setPasswordEncoder(new BCryptPasswordEncoder());
        daoAuthenticationProvider.setUserDetailsService(userDetailService);
        return daoAuthenticationProvider;
    }
    protected AuthenticationManager getAuthenticationManager()  {
        ProviderManager authenticationManager = new ProviderManager(Arrays.asList(getMyAuthenticationProvider(),daoAuthenticationProvider()));
        return authenticationManager;
    }

    public AccessDecisionManager accessDecisionManager(){
        List<AccessDecisionVoter<? extends Object>> decisionVoters
                = Arrays.asList(
                new MyExpressionVoter(),
                new WebExpressionVoter(),
                new RoleVoter(),
                new AuthenticatedVoter());
        return new UnanimousBased(decisionVoters);

    }
}
```

你可能想要用jwtToken 做token鉴权的方式；
也好做，我这里提一下思路，鉴权都是在投票器里面，那我们在投票器之前填充好securitycontext就成，然后实现一个自己的投票器；填充securitycontext随便找个过滤器http.addFilterAfter() 然后在过滤器里面填充好就行，至于拿token的接口，在config里用.permitAll()放行就行了，比上面的改法还简单，我就不写了。

#### 题外话

具体的代码可以参考我的项目[poseindon](https://github.com/muggle0/poseidon/wiki)，这种security改动方式我经过生产实践的，不会有问题。另外篇幅有点长 感谢大佬的阅读。
