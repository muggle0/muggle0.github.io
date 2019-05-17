---
title: gradle+idea 快速上手
date: 2019-05-15 17:29:58
tags: tool
---

## gradle介绍

Gradle是一个构建工具，定位和maven一样，用于管理项目依赖和构建项目。和maven比起来的优势是：语法更灵活，更方便管理项目（个人很讨厌XML）。

gradle具有以下特点：

- 按约定声明构建和建设；
- 强大的支持多工程的构建；
- 强大的依赖管理（基于Apache Ivy），提供最大的便利去构建工程；
- 全力支持已有的 Maven 或者Ivy仓库基础建设；
- 支持传递性依赖管理； 	
- 基于groovy脚本构建，groovy简单易学； 	
- 具有广泛的领域模型支持构建； 
- 易迁移； 
- 自由和开放源码；

<!--more-->

可以说是maven有得gradle也有，maven没有的gradle也有。gradle在windows下安装也很简单，和maven一样：

1. 从[gradle官网](<https://gradle.org/releases/>) 下载安装包并解压
2. 将解压的文件夹路径配置到环境变量，先添加一个`GRADLE_HOME` 然后在path下添加 `%GRADLE_HOME%\bin`
3. cmd跑 `gradle -v` 查看配置是否成功
4. [gradle 用户手册](<https://docs.gradle.org/current/userguide/userguide.html>) 方便平时查询相关操作

## gradle的基本使用

idea中已经集成gradle环境，你可以使用idea来构建gradle项目也可以通过命令行来使用gradle。在idea中 file-> setting ->搜索框输入gradle可查看gradle相关配置。

### 使用gradle新建项目

新建普通项目：
![new_normal.png](https://upload-images.jianshu.io/upload_images/13612520-7aec3520435c32c8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
新建springboot项目：

在如下图界面时选择`Gradle Project`即可 

![springboot.png](https://upload-images.jianshu.io/upload_images/13612520-cd7434a02af3bd86.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### gradle项目结构及配置文件说明

使用idea创建的gradle项目如图：
![dir.png](https://upload-images.jianshu.io/upload_images/13612520-681237c249232a34.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



src结构和maven无异，不再介绍；gradle文件夹 存放gradle wrapper相关文件；build.gradle相当于maven里面的pom.xml，setting.gradle用于多模块的配置。

gradle wrapper是gradle项目构建工具，它能在本地没有gradle的情况下，从远程下载gradle并自动解压缩以构建项目，自动管理gradle版本。`gradle-wrapper.properties`是gradle wrapper的配置，`distributionUrl`指定本地没有配置gradle的情况下从哪下载gradle，`distributionBase`指定gradle下载和缓存jar的根目录，默认用户目录。在实际使用中我们一般不直接使用gradle，而是使用gradle wrapper,而对于idea而言我们可以不去关心两者区别，idea的gradle环境是基于gradle wrapper的

build.gradle结构

```groovy
plugins {
    id 'java'
}
group 'com.muggle'
version '1.0-SNAPSHOT'
sourceCompatibility = 1.8
repositories {
    // mavenCentral()
    maven { url "http://maven.aliyun.com/nexus/content/groups/public/" }
}
dependencies {
    testCompile group: 'junit', name: 'junit', version: '4.12'
}

```

节点说明

- sourceCompatibility：指定编译.java文件的jdk版本
- plugins：插件配置；格式为`id «plugin id» version «plugin version» [apply «false»]` Gradle的核心插件只需提供id的简称就可以
- repositories：仓库配置，`mavenCentral()`代表中央仓库，你也可以用`maven{url  ‘<url>’}`的方式添加一个仓库
- dependencies：依赖的坐标集合

### dependencies说明

在idea中，你复制好maven的xml格式依赖 直接粘贴到`dependencies`节点里面它会自动调整成`compile 'groupId :artifactId:version' `而不需要我们手动去改（但似乎有个时候不管用）。

在gradle中，项目依赖的格式为`作用范修饰符 'groupId:artifactId:version'`，作用范围修饰符包括

1. complie：编译范围依赖在所有的 classpath 中可用，同时它们也会被打包，这个是最常用的
2. runtime：runtime 依赖在运行和测试系统的时候需要，但在编译的时候不需要。
3. testComplie：测试期编译需要的附加依赖
4. testRuntime：测试运行期需要

### gradle打包
![build.png](https://upload-images.jianshu.io/upload_images/13612520-d99c0ddc3495634b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
和在idea中使用maven一样，点击右侧gradle标签可看到上图相关gradle的操作，build对应的是`./gradlew build`命令；右键运行build会生成一个build文件夹 class文件和jar包都在里面。

## groovy 语言简单学习

Groovy 和java有很大程度上相似，学习成本低，只是为了更好使用gradle 简单学习Groovy 

在idea中打开groovy console 点击 tool->groovy console 打开

![groovy.png](https://upload-images.jianshu.io/upload_images/13612520-3d8398f4cdb5af0b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

写第一个程序

```groovy
// 这是一行注释
println ("test")
// 简写
println "ssssss"
```

ctrl+enter 执行代码

list map的应用

```groovy
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
// 添
map.test='add'
println map.get('test')
```

闭包的语法

```groovy
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

## gradle 实践

### 多模块

在idea中构建多模块很简单，和maven操作一样，但项目结构有所不同。在父模块中有一个`settings.gradle`文件，指定了子模块包含哪些，而需要继承给子模块的东西需要在父模块`build.gradle`中配置`subprojects`闭包。

父模块`build.gradle` 示例



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
    apply plugin: 'java'
    apply plugin: 'idea'

    version = '1.0'
    // JVM 版本号要求
    sourceCompatibility = 1.8
    targetCompatibility = 1.8
    // java编译的时候缺省状态下会因为中文字符而失败
    [compileJava,compileTestJava,javadoc]*.options*.encoding = 'UTF-8'
    //相当于maven的properties
    ext {
        springVersion = '4.3.3.RELEASE'
    }
    repositories {
        mavenCentral()
    }
    dependencies {
        // 通用依赖
        compile(
                "org.springframework:spring-context:$springVersion",
                "org.springframework:spring-orm:$springVersion",
        )
        // 依赖maven中不存在的jar
        ext.jarTree = fileTree(dir: 'libs', include: '**/*.jar')
        // 测试依赖
        testCompile(
                "org.springframework:spring-test:$springVersion",
                "junit:junit:4.12"
        )
    }
    // 显示当前项目下所有用于 compile 的 jar.
    task listJars(description: 'Display all compile jars.') << {
        configurations.compile.each { File file -> println file.name }
    }
}
```

子模块模块之间相互依赖方式：

```groovy
dependencies{  
    // 这个子模块 依赖 test 模块
    compile project(":test")  
}  
```

如果项目需要达成war包 添加插件`apply plugin: 'war'`。

### task

task是gradle中的任务，包括任务动作(task action)和任务依赖(task dependency)。task代表细分的下来的构建任务：编译classes、生成jar包相关信息等一些任务。所以我们能编写task来控制打包过程。task和task之间也存在依赖关系，通过`task dependency`来指定。

其实build指令本质就是执行各个task，在做protobuf开发的开发的时候我就可以通过配置task来在指定指定位置生成对应的java代码。

task 示例代码

```java
task first {
    doLast {
        println ">>>>>>>>>>>>>>"
    }
}
```
右击idea右侧gradle中的first执行task

				![demo.png](https://upload-images.jianshu.io/upload_images/13612520-25ae17571ab12d27.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


控制台输出：
```java

> Task :first
>>>>>>>>>>>>>>

```



## 总结

gradle相较maven来说更灵活，但现在市场占有率最大的还是maven，gradle在安卓开发的领域使用比较多。看过spring源码的就知道，spring就是用gradle来管理的。读完本篇博客后我希望你能顺畅的使用gradle构建一个普通的java项目、一个springboot项目、一个多模块项目。感谢阅读。