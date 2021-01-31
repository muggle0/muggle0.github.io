---
title: 写一个spring-boot-starter
date: 2019-05-15 16:27:12
tags: developing
---

废话不多说直接开始

1）新建maven项目，pom结构如下：

<!--more-->

```java
<groupId>com.muggle</groupId>
    <artifactId>test-spring-boot-starter</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.springframework/spring-webmvc -->


        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-autoconfigure</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webmvc</artifactId>
        </dependency>

  
       
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <!-- Import dependency management from Spring Boot -->
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>2.0.6.RELEASE</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
```

主要的依赖就是`spring-boot-configuration-processor`和`spring-boot-autoconfigure`一个是支持代码提示的依赖包，一个是自动化配置的依赖包。新建controller

```java
@RestController
public class TestController {

    @GetMapping("/test")
    public String test(){
        return "nihao";
    }
}
```

创建属性类，prefix = “helloworld”代表该项目在属性文件中配置的前缀，即可以在属性文件中通过 helloworld.words=springboot，就可以改变属性类字段 words 的值了。

```java
@ConfigurationProperties(prefix = "helloworld")
public class HelloworldProperties {
  public static final String DEFAULT_WORDS = "world";

  private String words = DEFAULT_WORDS;

  public String getWords() {
    return words;
  }

  public void setWords(String words) {
    this.words = words;
  }
}
```

添加自动化配置类

```java
@Configuration
@ConditionalOnClass(TestController.class)
@EnableConfigurationProperties(HelloworldProperties.class)
public class AutoConfig {

    @Bean
    @ConditionalOnMissingBean(TestController.class)//当容器中没有指定Bean的情况下
    public TestController bookService(){
        TestController bookService = new TestController();
        return bookService;
    }
}
```

在resource下新建`META-INF/spring.factories`内容为：

```java
org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.muggle.controller.AutoConfig
```

这个starter就算是做好了，很简单。