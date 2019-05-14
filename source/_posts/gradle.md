---
title: gradle学习笔记
date: 2019-05-09 09:24:16
tags: tool
---

什么是gradle

Gradle是一个构建工具，定位和maven一样，用于管理项目依赖和构建项目。和maven比起来的优势是：语法更灵活，更方便管理项目（个人很讨厌XML）。

gradle的特点：

按约定声明构建和建设； 	

 		强大的支持多工程的构建； 	

 		强大的依赖管理（基于Apache Ivy），提供最大的便利去构建工程； 	

 		全力支持已有的 Maven 或者Ivy仓库基础建设； 	

 		支持传递性依赖管理，在不需要远程仓库和pom.xml和ivy配置文件的前提下； 	

 		基于groovy脚本构建，其build脚本使用groovy语言编写； 	

 		具有广泛的领域模型支持构建； 	

 		深度 API； 	

 		易迁移； 	

 		自由和开放源码，Gradle是一个开源项目，基于 [ASL](http://www.gradle.org/license?_ga=1.156736505.391095409.1474008833) 许可。

gradle 安装

和maven安装方式一样，如果你使用idea的话，idea自身集成了gradle，可以免安装使用。

下面简单说一下安装过程：

[gradle 下载](http://www.gradle.org/downloads) 下载后解压 ，配置环境变量GRADLE_HOME，path下添加%GRADLE_HOME%/bin；这里不再细说

idea下使用gradle

![1557365733977](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1557365733977.png)

![1557365771206](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1557365771206.png)

添加依赖

```java
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```
通常我们 使用 compile 'groupId :artifactId:version' 就能添加一个依赖 如：

```java
compile 'org.springframework:spring-context:4.2.1.RELEASE'
```

gradle打jar包方式略微复杂，后文介绍

gradle高级使用

Groovy语法简单介绍

Groovy 和java有很大程度上相似，学习成本低，只是为了更好使用gradle 简单学习Groovy 

![1557366677911](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1557366677911.png)

```groovy
// 这是一行注释
println ("ssssss")
```

ctrl+enter 执行代码

现在通过代码说明定义 变量集合 和map并使用

```groovy
// 这是一行注释

println ("ssssss");

// 简写
println "ssssss"

// 定义变量 相当于var 弱类型
def i=15
println(i)
def s ="nihao"
println s
// 集合定义
def list=['s','a']
// 添加元素
list << 'c'
// 取出 元素
println list.get(0)
println list.get(0)
// map
def map=['key':'value']
println map.get('key')
// 添加
map.test='add'
println map.get('test')
```

闭包

```
// 闭包 相当于函数式编程
def close1={
    println "你好"
}
// 方法定义
def test(Closure closure){
    closure()
}
//使用闭包
test(close1)
// 带参闭包
def  close2={
    v-> println v+v+v
}
def test2(Closure closure){
    closure("sss")
}
//使用带参闭包
test2(close2)
// 占位符
def close3={
    v->
        println("test $v ")
}
test2(close3)
```

gradle配置文件介绍及在idea中gradle深度使用

1. 对于maven 直接复制粘贴，gradle自动转换
2. build.gradle，gradle的构建配置，这是我们要关心的，相当于Maven的pom.xml
3. gradlew.bat，一段gradle wrapper的运行脚本，For Windows

![1557370509524](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1557370509524.png)

项目依赖的集合，可以清晰的看到 test 和main分别依赖哪些jar

Gradle 默认会从 `src/main/java` 搜寻打包源码，在 `src/test/java` 下搜寻测试源码。并且 `src/main/resources` 下的所有文件按都会被打包，所有 `src/test/resources` 下的文件 都会被添加到类路径用以执行测试。所有文件都输出到 build 下，打包的文件输出到 build/libs 下。

指令介绍

当你执行 gradle build 时，Gralde 会编译并执行单元测试，并且将 `src/main/*` 下面 class 和资源文件打包。

#### clean

删除 build 目录以及所有构建完成的文件。

操作和maven类似

多项目构建

settings.gradle

![1557389426506](C:\Users\isock\AppData\Roaming\Typora\typora-user-images\1557389426506.png)

```groovy
rootProject.name = 'gradle-test'
include 'test-first'
include 'test-second'
```

继承

```groovy
plugins {
    id 'java'
}

group 'com.muggle'
version '1.0-SNAPSHOT'

sourceCompatibility = 1.8

repositories {
    mavenCentral()
}


subprojects {

    ext {
        junitVersion = "4.11"
        springVersion = "4.3.3.RELEASE"
        jacksonVersion = "2.4.4"
        compileJava.options.encoding = 'UTF-8'
        compileTestJava.options.encoding = 'UTF-8'
    }
    dependencies {
        testCompile group: 'junit', name: 'junit', version: '4.12'
        compile 'org.springframework.boot:spring-boot-starter-web:2.1.4.RELEASE'
    }
}
```

plugins 节点

插件配置

```json
plugins {
id «plugin id» version «plugin version» [apply «false»]
}
```

Gradle的核心插件比较特殊，你只需提供id的简称就可以

```
repositories {
    mavenCentral()
}
```

repositories

```java
repositories {
mavenCentral()
maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
}
```

ext

