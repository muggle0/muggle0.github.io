---
title: springSecurity深度解析第二版
date: 2019-04-20 12:44:15
tags: security
---
作者：muggle
# 前言

由于第一版排版实在太过糟糕，而且很多细节没交代清楚，所以决定写第二版；这一版争取将排版设计得清晰明了一点，以方便读者阅读。
<!-- more -->
# security原理分析

## springSecurity过滤器链

springSecurity 采用的是责任链的设计模式，它有一条很长的过滤器链。现在对这条过滤器链的各个进行说明

> 1. WebAsyncManagerIntegrationFilter：将Security上下文与Spring Web中用于处理异步请求映射的 WebAsyncManager 进行集成。
>
> 2. SecurityContextPersistenceFilter：在每次请求处理之前将该请求相关的安全上下文信息加载到SecurityContextHolder中，然后在该次请求处理完成之后，将SecurityContextHolder中关于这次请求的信息存储到一个“仓储”中，然后将SecurityContextHolder中的信息清除
>    例如在Session中维护一个用户的安全信息就是这个过滤器处理的。
>
> 3. HeaderWriterFilter：用于将头信息加入响应中
> 4. CsrfFilter：用于处理跨站请求伪造
> 5. LogoutFilter：用于处理退出登录
> 6. UsernamePasswordAuthenticationFilter：用于处理基于表单的登录请求，从表单中获取用户名和密码。默认情况下处理来自“/login”的请求。从表单中获取用户名和密码时，默认使用的表单name值为“username”和“password”，这两个值可以通过设置这个过滤器的usernameParameter 和 passwordParameter 两个参数的值进行修改。
> 7. DefaultLoginPageGeneratingFilter：如果没有配置登录页面，那系统初始化时就会配置这个过滤器，并且用于在需要进行登录时生成一个登录表单页面。
> 8. BasicAuthenticationFilter：检测和处理http basic认证
> 9. RequestCacheAwareFilter：用来处理请求的缓存
> 10. SecurityContextHolderAwareRequestFilter：主要是包装请求对象request
> 11. AnonymousAuthenticationFilter：检测SecurityContextHolder中是否存在Authentication对象，如果不存在为其提供一个匿名Authentication
> 12. SessionManagementFilter：管理session的过滤器
> 13. ExceptionTranslationFilter：处理 AccessDeniedException 和 AuthenticationException 异常
> 14. FilterSecurityInterceptor：可以看做过滤器链的出口
> 15. RememberMeAuthenticationFilter：当用户没有登录而直接访问资源时, 从cookie里找出用户的信息, 如果Spring Security能够识别出用户提供的remember me cookie, 用户将不必填写用户名和密码, 而是直接登录进入系统，该过滤器默认不开启。

## springSecurity 流程图

上一版是通过debug的方法告诉读者springSecurity的一个执行过程，发现反而把问题搞复杂了，这一版我决定画一个流程图来说明其执行过程，只要把springSecurity的执行过程弄明白了，这个框架就会变得很简单

<!--more-->

![security.png](https://upload-images.jianshu.io/upload_images/13612520-e6bfb247ef6edf01.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000/format/webp)

## 流程说明

1. 客户端发起一个请求，进入security过滤器链；

2. 当到LogoutFilter的时候判断是否是登出路径，如果是登出路径则到logoutHandler，如果登出成功则到logoutSuccessHandler登出成功处理，如果登出失败则由ExceptionTranslationFilter；如果不是登出路径则直接进入下一个过滤器；

3. 当到UsernamePasswordAuthenticationFilter的时候判断是否为登陆路径，如果是，则进入该过滤器进行登陆操作，如果登陆失败则到AuthenticationFailureHandler登陆失败处理器处理，如果登陆成功则到AuthenticationSuccessHandler登陆成功处理器处理 ；如果不是登陆请求则不进入该过滤器

4. 当到FilterSecurityInterceptor的时候会拿到urI，根据uri去找对应的鉴权管理器，鉴权管理器做鉴权工作，鉴权成功则到controller层否则到AccessDeniedHandler鉴权失败处理器处理

   

# security配置

在`WebSecurityConfigurerAdapter`这个类里面可以完成上述流程图的所有配置



## 配置类伪代码

```java
 **/
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.userDetailsService(userDetailService).passwordEncoder(new BCryptPasswordEncoder());
    }
    @Override
    public void configure(WebSecurity web) throws Exception {

        web.ignoring().antMatchers("/resources/**/*.html", "/resources/**/*.js");
    }
    @Override
    protected void configure(HttpSecurity http) throws Exception {
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test")
               .anyRequest().authenticated().accessDecisionManager(accessDecisionManager())
               .and().logout().logoutSuccessHandler(new MyLogoutSuccessHandler())
               .and().csrf().disable();
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
        http.exceptionHandling().accessDeniedHandler(new MyAccessDeniedHandler());
        http.addFilterAfter(new MyFittler(), LogoutFilter.class);
    }
}

```

## 配置类说明

###  configure(AuthenticationManagerBuilder auth) 说明

AuthenticationManager的建造器，配置AuthenticationManagerBuilder 会让security自动构建一个AuthenticationManager（该类的功能参考流程图）；如果想要使用该功能你需要配置一个UserDetailService和passwordEncoder。userDetailsService用于在认证器中根据用户传过来的用户名查找一个用户，passwordEncoder用于密码的加密与比对，我们存储用户密码的时候用passwordEncoder.encode()加密存储，在认证器里会调用passwordEncoder.matches()方法进行密码比对。

如果重写了该方法，security会启用DaoAuthenticationProvider这个认证器，该认证就是先调用UserDetailsService.loadUserByUsername然后使用passwordEncoder.matches()进行密码比对，如果认证成功成功则返回一个Authentication对象

### configure(WebSecurity web)说明

这个配置方法用于配置静态资源的处理方式，可使用ant匹配规则

### configure(HttpSecurity http) 说明

这个配置方法是最关键的方法，也是最复杂的方法。我们慢慢掰开来说

```java
http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
```

这是配置登陆相关的操作从方法名可知，配置了登录页请求路径，密码属性名，用户名属性名，和登陆请求路径，permitAll()代表任意用户可访问

```java
http.authorizeRequests().antMatchers("/test").hasRole("test").anyRequest().authenticated().accessDecisionManager(accessDecisionManager());
```

以上配置是权限相关的配置，配置了一个“/test” url该有什么权限才能访问，anyRequest()表示所有请求，authenticated()表示已登录用户，accessDecisionManager（）表示绑定在url上的鉴权管理器

为了对比，现在贴出另一个权限配置清单

```
http.authorizeRequests().antMatchers("/tets_a/**","/test_b/**").hasRole("test").antMatchers("/a/**","/b/**").authenticated().accessDecisionManager(accessDecisionManager())
```

我们可以看到权限配置的自由度很高，鉴权管理器可以绑定到任意url上；而且可以硬编码各种url权限;

```java
http.logout().logoutUrl("/logout").logoutSuccessHandler(new MyLogoutSuccessHandler())
```

登出相关配置，这里配置了登出url和登出成功处理器

```java
http.exceptionHandling().accessDeniedHandler(new MyAccessDeniedHandler());
```

上面代码是配置鉴权失败的处理器

```java
http.addFilterAfter(new MyFittler(), LogoutFilter.class);
http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
```

上面代码展示如何在过滤器链中插入自己的过滤器，addFilterBefore加在对应的过滤器之前addFilterAfter之后，addFilterAt加在过滤器同一位置，事实上框架原有的Filter在启动HttpSecurity配置的过程中，都由框架完成了其一定程度上固定的配置，是不允许更改替换的。根据测试结果来看，调用addFilterAt方法插入的Filter，会在这个位置上的原有Filter之前执行。

注：关于HttpSecurity使用的是链式编程，其中http.xxxx.and.yyyyy这种写法和http.xxxx;http.yyyy写法意义一样。

### 自定义authenticationManager和accessDecisionManager

重写authenticationManagerBean()方法，并构造一个authenticationManager

```java
@Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        ProviderManager authenticationManager = new ProviderManager(Arrays.asList(getMyAuthenticationProvider(),daoAuthenticationProvider()));
        return authenticationManager;
    }
```

我这里给authenticationManager配置了两个认证器，执行过程参考流程图

定义构造AccessDecisionManager的方法并在配置类中调用，配置参考 configure(HttpSecurity http) 说明

```java
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

投票管理器会收集投票器投票结果做统计，最终结果大于等于0代表通过；每个投票器会返回三个结果：-1（反对），0（通过），1（赞成）。

# security 权限用户系统说明

## UserDetails

security中的用户接口，我们自定义用户类要实现该接口，各个属性的含义自行百度

## GrantedAuthority

security中的用户权限接口，自定义权限需要实现该接口

```java
@Data
public class MyGrantedAuthority implements GrantedAuthority {
    private String authority;
}
```

authority权限字段，需要注意的是在config中配置的权限会被加上ROLE_前缀，比如我们的配置authorizeRequests().antMatchers("/test").hasRole("test")，配置了一个“test”权限但我们存储的权限字段（authority）应该是“ROLE_test”

## UserDetailsService

security用户service，自定义用户服务类需要实现该接口

```java
@Service
public class MyUserDetailService implements UserDetailsService {
    @Override
    public UserDetails loadUserByUsername(String s) throws UsernameNotFoundException {
      return.....
    }
}
```

loadUserByUsername的作用在上文中已经说明；

## SecurityContextHolder

用户在完成登陆后security会将用户信息存储到这个类中，之后其他流程需要得到用户信息时都是从这个类中获得，用户信息被封装成SecurityContext ，而实际存储的类是SecurityContextHolderStrategy ，默认的SecurityContextHolderStrategy 实现类是ThreadLocalSecurityContextHolderStrategy 它使用了ThreadLocal来存储了用户信息。

手动填充SecurityContextHolder示例：

```java
UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken("test","test",list);
SecurityContextHolder.getContext().setAuthentication(token);
```

对于token鉴权的系统

我们就可以验证token后手动填充SecurityContextHolder，填充时机只要在执行投票器之前即可，或者干脆可以在投票器中填充，然后在登出操作中清空SecurityContextHolder。

# security扩展说明

可扩展的有

- 鉴权失败处理器：security鉴权失败默认跳转登陆页面，我们可以
- 验证器
- 登陆成功处理器
- 投票器
- 自定义token处理过滤器
- 登出成功处理器
- 登陆失败处理器
- 自定义UsernamePasswordAuthenticationFilter

## 鉴权失败处理器

security鉴权失败默认跳转登陆页面，我们可以实现AccessDeniedHandler接口，重写handle()方法来自定义处理逻辑；然后参考配置类说明将处理器加入到配置当中

## 验证器

实现AuthenticationProvider接口来实现自己验证逻辑。需要注意的是在这个类里面就算你抛出异常，也不会中断验证流程，而是算你验证失败，我们由流程图知道，只要有一个验证器验证成功，就算验证成功，所以你需要留意这一点

## 登陆成功处理器

在security中验证成功默认跳转到上一次请求页面或者路径为"/"的页面，我们同样可以自定义：继承SimpleUrlAuthenticationSuccessHandler这个类或者实现AuthenticationSuccessHandler接口。我这里建议采用继承的方式；SimpleUrlAuthenticationSuccessHandler是默认的处理器，采用继承可以契合里氏替换原则，提高代码的复用性和避免不必要的错误。

## 投票器

投票器可继承WebExpressionVoter或者实现AccessDecisionVoter<FilterInvocation>接口；WebExpressionVoter是security默认的投票器；我这里同样建议采用继承的方式；添加到配置的方式参考 配置类说明章节；

注意：投票器vote方法返回一个int值；-1代表反对，0代表弃权，1代表赞成；投票管理器收集投票结果，如果最终结果大于等于0则放行该请求。

## 自定义token处理过滤器

自定义token处理器继承自可OncePerRequestFilter或者GenericFilterBean或者Filter都可以，在这个处理器里面需要完成的逻辑是：获取请求里的token，验证token是否合法然后填充SecurityContextHolder，虽然说过滤器只要添加在投票器之前就可以；但我这里还是建议添加在http.addFilterAfter(new MyFittler(), LogoutFilter.class);

## 登出成功处理器

实现LogoutSuccessHandler接口，添加到配置的方式参考 配置类说明章节

## 登陆失败处理器

登陆失败默认跳转到登陆页，我们同样可以自定义。继承SimpleUrlAuthenticationFailureHandler 或者实现AuthenticationFailureHandler；建议采用继承。

## 自定义UsernamePasswordAuthenticationFilter

我们自定义UsernamePasswordAuthenticationFilter可以极大提高我们security的灵活性（比如添加验证验证码是否正确的功能），所以我这里是建议自定义UsernamePasswordAuthenticationFilter；

我们直接继承UsernamePasswordAuthenticationFilter，然后在配置类中初始化这个过滤器，给这个过滤器添加登陆失败处理器，登陆成功处理器，登陆管理器，登陆请求url

这里配置略微复杂，贴一下代码清单

初始化过滤器：

```java
MyUsernamePasswordAuthenticationFilte getAuthenticationFilter(){
        MyUsernamePasswordAuthenticationFilte myUsernamePasswordAuthenticationFilte = new MyUsernamePasswordAuthenticationFilte(redisService);
        myUsernamePasswordAuthenticationFilte.setAuthenticationFailureHandler(new MyUrlAuthenticationFailureHandler());
        myUsernamePasswordAuthenticationFilte.setAuthenticationSuccessHandler(new MyAuthenticationSuccessHandler());
        myUsernamePasswordAuthenticationFilte.setFilterProcessesUrl("/sign_in");
        myUsernamePasswordAuthenticationFilte.setAuthenticationManager(getAuthenticationManager());
        return myUsernamePasswordAuthenticationFilte;
    }
```

添加到配置：

```java
http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
```

# 代码清单

下面贴出适配于 前后端分离和token验证的伪代码清单

## 登陆页请求处理

```java
@Controller
public class LoginController {
    /** 
    * @Description: 登陆页面的请求 
    * @Param:  
    * @return:  
    */ 
    @GetMapping("/login_page")
    public String loginPage(){
        return "loginPage.html";
    }
}
```

## 鉴权失败处理器

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

## 验证器

```java
public class MyAuthenticationProvider  implements AuthenticationProvider {
    private UserDetailsService userDetailsService;
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    public MyAuthenticationProvider(UserDetailsService userDetailsService, BCryptPasswordEncoder bCryptPasswordEncoder) {
        this.userDetailsService = userDetailsService;
        this.bCryptPasswordEncoder = bCryptPasswordEncoder;
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
//       这里写验证逻辑
        return null;
    }

    @Override
    public boolean supports(Class<?> aClass) {
        return true;
    }
}
```

## 验证成功处理器

```java
ublic class MyAuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
        //随便写点啥
    }
}
```

## 投票器

```java
/**
 * @program: security-test
 * @description: 鉴权投票器
 * @author: muggle
 * @create: 2019-04-11
 **/

public class MyExpressionVoter extends WebExpressionVoter {
    @Override
    public int vote(Authentication authentication, FilterInvocation fi, Collection<ConfigAttribute> attributes) {
//        这里写鉴权逻辑
        System.out.println(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        return 1 ;
    }
}
```

## 自定义token处理过滤器

```java
/**
 * @program: security-about
 * @description:填充一个token
 * @author: muggle
 * @create: 2019-04-20
 **/

public class MyFittler extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String token1 = request.getHeader("token");
        if (token1==null){

        }

        ArrayList<GrantedAuthority> list = new ArrayList<>();
        GrantedAuthority grantedAuthority = new GrantedAuthority() {
            @Override
            public String getAuthority() {
                return "test";
            }
        };
        list.add(grantedAuthority);
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken("test","test",list);
        SecurityContextHolder.getContext().setAuthentication(token);
        filterChain.doFilter(request, response);
    }
}
```

## 登出成功处理器

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

## 登陆失败处理器

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

## 自定义UsernamePasswordAuthenticationFilter

```java
/**
 * @program: security-test
 * @description: 用户登陆逻辑过滤器
 * @author: muggle
 * @create: 2019-04-11
 **/

public class MyUsernamePasswordAuthenticationFilte extends UsernamePasswordAuthenticationFilter {
    private RedisService redisService;
    private boolean postOnly = true;

    public MyUsernamePasswordAuthenticationFilte(RedisService redisService){
        this.redisService=redisService;
    }

    @Override
    public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) throws AuthenticationException {
     
        //你可以在这里做验证码校验，校验不通过抛出AuthenticationException()即可
            super.attemptAuthentication(request,response);
    }
}
```

## 配置

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Autowired
    RedisService redisService;
    @Autowired
    MyUserDetailService userDetailService;
  
    @Override
    public void configure(WebSecurity web) throws Exception {

        web.ignoring().antMatchers("/resources/**/*.html", "/resources/**/*.js",
                "/resources/**/*.css", "/resources/**/*.txt",
                "/resources/**/*.png", "/**/*.bmp", "/**/*.gif", "/**/*.png", "/**/*.jpg", "/**/*.ico");
//        super.configure(web);
    }


    @Override
    protected void configure(HttpSecurity http) throws Exception {
//        配置登录页等 permitAll表示任何权限都能访问
       http.formLogin().loginPage("/login_page").passwordParameter("username").passwordParameter("password").loginProcessingUrl("/sign_in").permitAll()
               .and().authorizeRequests().antMatchers("/test").hasRole("test")
//               任何请求都被accessDecisionManager() 的鉴权器管理
               .anyRequest().authenticated().accessDecisionManager(accessDecisionManager())
//               登出配置
               .and().logout().logoutUrl("/logout").logoutSuccessHandler(new MyLogoutSuccessHandler())
//               关闭csrf
               .and().csrf().disable();
       http.authorizeRequests().antMatchers("/tets_a/**","/test_b/**").hasRole("test").antMatchers("/a/**","/b/**").authenticated().accessDecisionManager(accessDecisionManager())
//      加自定义过滤器
        http.addFilterAt(getAuthenticationFilter(),UsernamePasswordAuthenticationFilter.class);
//        配置鉴权失败的处理器
        http.exceptionHandling().accessDeniedHandler(new MyAccessDeniedHandler());
        http.addFilterAfter(new MyFittler(), LogoutFilter.class);

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

# 总结

对于security的扩展配置关键在于`configure(HttpSecurity http)`方法；扩展认证方式可以自定义`authenticationManager`并加入自己验证器，在验证器中抛出异常不会终止验证流程；扩展鉴权方式可以自定义`accessDecisionManager`然后添加自己的投票器并绑定到对应的url（url 匹配方式为ant）上，投票器`vote(Authentication authentication, FilterInvocation fi, Collection<ConfigAttribute> attributes)`方法返回值为三种：-1 0 1，分别表示反对弃权赞成；

对于token认证的校验方式，可以暴露一个获取的接口，或者重写`UsernamePasswordAuthenticationFilter`过滤器和扩展登陆成功处理器来获取token，然后在`LogoutFilter`之后添加一个自定义过滤器，用于校验和填充SecurityContextHolder

security的处理器大部分都是重定向的，我们的项目如果是前后端分离的话，我们希望无论什么情况都返回json,那么就需要重写各个处理器了。

##  勘误

2018/6/23: 在和别人讲解security的时候发现漏了一个处理器，401用户未登陆处理器，其默认是跳转到登陆页；现贴出其写法和配置方法，使其返回



```java
/**
 * @program: poseidon
 * @description: 未登录处理
 * @author: muggle
 * @create: 2018-12-31
 **/
public class PoseidonLoginUrlAuthenticationEntryPoint extends LoginUrlAuthenticationEntryPoint {
    public PoseidonLoginUrlAuthenticationEntryPoint(String loginFormUrl) {
        super(loginFormUrl);
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) throws IOException, ServletException {
        response.setContentType("application/json;charset=UTF-8");
        final PrintWriter writer = response.getWriter();
        writer.write("{\"code\":\"401\",\"msg\":\"用户未登录\"}");
        writer.close();
    }
}
```

在config 方法中加上

```java
http.exceptionHandling().authenticationEntryPoint( new PoseidonLoginUrlAuthenticationEntryPoint("/login")).accessDeniedHandler(new PoseidonAccessDeniedHandler());
```

具体细节可参看我的poseidon项目和sofia脚手架。