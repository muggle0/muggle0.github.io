---
title: 设计模式—建造者模式(Builder)
date: 2020-02-02 17:31:32
tags: 设计模式
---

建造者模式(Builder)是一步一步创建一个复杂的对象，它允许用户只通过指定复杂对象的类型和内容就可以构建它们，用户不需要知道内部的具体构建细节。建造者模式属于对象创建型模式。我们获得一个对象的时候不是直接new这个对象出来，而是对其建造者进行属性设置，然后建造者在根据设置建造出各个对象出来。建造者模式又可以称为生成器模式。



## 模式结构

一个标准的建造者模式包含如下角色：

- Builder：抽象建造者
- ConcreteBuilder：具体建造者
- Director：指挥者
- Product：产品角色

## 源码导读

建造者模式使用比较简单，场景也比较清晰。protobuf中protobuf对应的java类就是使用建造者模式来创建对象的。

```
public static PersonEntity.Person create() {    PersonEntity.Person person = PersonEntity.Person.newBuilder()            .setId(1)            .setName("Pushy")            .setEmail("1437876073@qq.com")            .build();    System.out.println(person);    return person;}
```

一般建造者模式结合**链式编程**来使用，代码上更加美观。

```
spring security`中也有使用到建造者模式，其 `AuthenticationManagerBuilder`是 `AuthenticationManager`的建造者，我们可以通过配置 `AuthenticationManagerBuilder`来建造一个 `AuthenticationManager
public class SecurityConfig extends WebSecurityConfigurerAdapter {    @Override    protected void configure(AuthenticationManagerBuilder auth) throws Exception {        auth.userDetailsService(userDetailsService).passwordEncoder(passwordEncoder);    }}
```

我们来看看 `AuthenticationManagerBuilder`

```
public class AuthenticationManagerBuilder extends AbstractConfiguredSecurityBuilder<AuthenticationManager, AuthenticationManagerBuilder> implements ProviderManagerBuilder<AuthenticationManagerBuilder> {    ......    ......     public final AuthenticationManager build() throws Exception {        if (this.building.compareAndSet(false, true)) {            this.object = this.doBuild();            return this.object;        } else {            throw new AlreadyBuiltException("This object has already been built");        }    }}
```

这里抽象建造者是 `ProviderManagerBuilder`，具体建造者是 `AuthenticationManagerBuilder`，被建造的对象是 `AuthenticationManager` 建造方法是 `build()`方法。

一般建造者模式中建造者类命名以 `builder`结尾，而建造方法命名为 `build()`。

lombok中@builder就是对实体类使用创造者模式，如果你项目中用到了lombok那么使用建造者模式就很方便，一个注解搞定。