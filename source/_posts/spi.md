---
title: spi和jar
date: 2019-05-17 11:47:30
tags: javase
---

今天介绍两个大家每天都在用但是却很少去了解它的知识点：spi和jar运行机制，废话不多说，开始正题

# spi

是Java提供的一套用来被第三方实现或者扩展的API，它可以用来启用框架扩展和替换组件。spi机制是这样的：读取`META-INF/services/`目录下的元信息，然后ServiceLoader根据信息加载对应的类，你可以在自己的代码中使用这个被加载的类。要使用Java SPI，需要遵循如下约定：

<!--more-->

- 当服务提供者提供了接口的一种具体实现后，在jar包的META-INF/services目录下创建一个以“接口全限定名”为命名的文件，内容为实现类的全限定名；
- 接口实现类所在的jar包放在主程序的classpath中；
- 主程序通过java.util.ServiceLoder动态装载实现模块，它通过扫描META-INF/services目录下的配置文件找到实现类的全限定名，把类加载到JVM；
- SPI的实现类必须携带一个不带参数的构造方法；

现在我们来简单的使用一下吧

## spi使用示例

建一个maven项目，定义一个接口 (`com.test.SpiTest`)，并实现该接口（`com.test.SpiTestImpl`）；然后在 `src/main/resources/` 下建立 `/META-INF/services` 目录， 新增一个以接口命名的文件 (`com.test.SpiTest`)，内容是要应用的实现类（`com.test.SpiTestImpl`）。

```java
public interface SpiTest {
    void test();
}


public class SpiTestImpl implements SpiTest {
    @Override
    public void test() {
        System.out.println("test");
    }
}

```



然后在我们的应用程序中使用 `ServiceLoader `来加载配置文件中指定的实现。

```java
public static void main(String[] args) {
        ServiceLoader<SpiTest> load = ServiceLoader.load(SpiTest.class);
        SpiTest next = load.iterator().next();
        next.test();
      
    }
```

这便是spi的使用方式了，简约而不简单

## spi技术的应用

那这一项技术有哪些方面的应用呢？最直接的jdbc中我们需要指定数据库驱动的全限定名，这便是spi技术。还有不少框架比如dubbo，都会预留spi扩展点比如：[dubbo spi](<http://dubbo.apache.org/zh-cn/docs/dev/impls/protocol.html>)

为什么要这么做呢？在spring框架中我们注入一个bean 很容易，通过注解或者xml配置即可，然后在其他的地方就能使用这个bean。在非spring框架下，我们想要有同样的效果就可以考虑spi技术了。

写过springboot 的starter的都知道，需要在 `src/main/resources/` 下建立 `/META-INF/spring.factories` 文件。这其实也是一种spi技术的变形。

# jar机制

通常项目中我们打jar包都是通过maven来进行的，导致很多人忽略了这个东西的存在，就像很多人不知道jdb.exe 是啥玩意一样。下面我们不借助任何工具来打一个jar包并对jar文件结构进行解析。

## 命令行打jar包

首先我们建立一个普通的java项目，新建几个class类，然后在根目录下新建`META-INF/MAINFEST.MF` 这个文件包含了jar的元信息，当我们执行java -jar的时候首先会读取该文件的信息做相关的处理。我们来看看这个文件中可以配置哪些信息 ：

- Manifest-Version：用来定义manifest文件的版本，例如：Manifest-Version: 1.0
- Main-Class：定义jar文件的入口类，该类必须是一个可执行的类，一旦定义了该属性即可通过 java -jar x.jar来运行该jar文件。
- Class-Path：指定该jar包所依赖的外部jar包，以当前jar包所在的位置为相对路径，无法指定jar包内部的jar包
- 签名相关属性，包括`Name`，`Digest-Algorithms`，`SHA-Digest`等

定义好元信息之后我们就可以打jar包了，以下是打包的一些常用命令

```shell
/* 1. 默认打包 */
// 生成的test.jar中就含test目录和jar自动生成的META-INF目录（内含MAINFEST.MF清单文件）
jar -cvf test.jar test

/* 2. 查看包内容 */
jar -tvf test.jar

/* 3. 解压jar包 */
jar -xvf test.jar

/* 4. 提取jar包部分内容 */
jar -xvf test.jar test\test.class

/* 5. 追加内容到jar包 */
//追加MAINFEST.MF清单文件以外的文件，会追加整个目录结构
jar -uvf test.jar other\ss.class

//追加清单文件，会追加整个目录结构(test.jar会包含META-INF目录)
jar -uMvf test.jar META-INF\MAINFEST.MF

/* 6. 创建自定义MAINFEST.MF的jar包 */
jar -cMvf test.jar test META-INF

// 通过-m选项配置自定义MAINFEST.MF文件时，自定义MAINFEST.MF文件必须在位于工作目录下才可以
jar -cmvf MAINFEST.MF test.jar test
```

## jar运行的过程

jar运行过程和类加载机制有关，而类加载机制又和我们自定义的类加载器有关，现在我们先来了解一下双亲委派模式。

java中类加载器分为三个：

- BootstrapClassLoader负责加载`${JAVA_HOME}/jre/lib`部分jar包
- ExtClassLoader加载`${JAVA_HOME}/jre/lib/ext`下面的jar包
- AppClassLoader加载用户自定义-classpath或者Jar包的Class-Path定义的第三方包

类的生命周期为：加载（Loading）、验证（Verification）、准备(Preparation)、解析(Resolution)、初始化(Initialization)、使用(Using) 和 卸载(Unloading)七个阶段。

当我们执行 java -jar的时候 jar文件以二进制流的形式被读取到内存，但不会加载到jvm中，类会在一个合适的时机加载到虚拟机中。类加载的时机：

- 遇到new、getstatic、putstatic或invokestatic这四条字节码指令时，如果类没有进行过初始化，则需要先对其进行初始化。成这四条指令的最常见的Java代码场景是使用new关键字实例化对象的时候，读取或设置一个类的静态字段调用一个类的静态方法的时候。
- 使用java.lang.reflect包的方法对类进行反射调用的时候，如果类没有进行过初始化，则需要先触发其初始化。
- 当初始化一个类的时候，如果发现其父类还没有进行过初始化，则需要先触发其父类的初始化。
- 当虚拟机启动时，用户需要指定一个要执行的主类（包含main()方法的那个类），虚拟机会先初始化这个主类。

当触发类加载的时候，类加载器也不是直接加载这个类。首先交给`AppClassLoader`，它会查看自己有没有加载过这个类，如果有直接拿出来，无须再次加载，如果没有就将加载任务传递给`ExtClassLoader`，而`ExtClassLoader`也会先检查自己有没有加载过，没有又会将任务传递给`BootstrapClassLoader`，最后`BootstrapClassLoader`会检查自己有没有加载过这个类，如果没有就会去自己要寻找的区域去寻找这个类，如果找不到又将任务传递给`ExtClassLoader`，以此类推最后才是`AppClassLoader`加载我们的类。这样做是确保类只会被加载一次。通常我们的类加载器只识别classpath（这里的classpath指项目根路径，也就是jar包内的位置）下.class文件。jar中其他的文件包括jar包被当做了资源文件，而不会去读取里面的.class 文件。但实际上我们可以通过自定义类加载器来实现一些特别的操作

## Tomcat 的类加载器

Tomcat的类加载机制是违反了双亲委托原则的，对于一些未加载的非基础类(Object,String等)，各个web应用自己的类加载器(WebAppClassLoader)会优先加载，加载不到时再交给commonClassLoader走双亲委托。

tomcat的类加载器：

- Common类加载器：负责加载/common目录的类库，这儿存放的类库可被tomcat以及所有的应用使用。
- Catalina类加载器：负责加载/server目录的类库，只能被tomcat使用。
- Shared类加载器：负载加载/shared目录的类库，可被所有的web应用使用，但tomcat不可使用。
- WebApp类加载器：负载加载单个Web应用下classes目录以及lib目录的类库，只能当前应用使用。
- Jsp类加载器：负责加载Jsp，每一个Jsp文件都对应一个Jsp加载器。

我们将一堆jar包放到tomcat的项目文件夹下，tomcat 运行的时候能加载到这些jar包的class就是因为这些类加载器对读取到的二进制数据进行处理解析从中拿到了需要的类

## springboot的jar包的特别之处

当我们将一个springboot项目打好包之后，不妨解压看看里面的结构是什么样子的的

```java
run.jar
|——org
|  |——springframework
|     |——boot
|        |——loader
|           |——JarLauncher.class
|           |——Launcher.class
|——META-INF
|  |——MANIFEST.MF  
|——BOOT-INF
|  |——class
|     |——Main.class
|     |——Begin.class
|  |——lib
|     |——commons.jar
|     |——plugin.jar
|  |——resource
|     |——a.jpg

|     |——b.jpg

```

`classpath`可加载的类只有`JarLauncher.class`，`Launcher.class`，`Main.class`，`Begin.class`。在`BOOT-INF/lib`和`BOOT-INF/class`里面的文件不属于classloader搜素对象直接访问的话会报`NoClassDefDoundErr`异常。Jar包里面的资源以 `Stream` 的形式存在（他们本就处于Jar包之中），java程序时可以访问到的。当springboot运行main方法时在main中会运行`org.springframework.boot.loader.JarLauncher`和`Launcher.class`这两个个加载器（你是否还及得前文提到过得spi技术），这个加载器去加载受stream中的jar包中的class。这样就实现了加载jar包中的jar这个功能否则正常的类加载器是无法加载jar包中的jar的class的，只会根据`MAINFEST.MF`来加载jar外部的jar来读取里面的class。

## 如何自定义类加载器

1）继承ClassLoader    重写findClass（）方法  

```java
public class MyClassLoader extends ClassLoader{

    private String classpath;
    
    public MyClassLoader(String classpath) {
        
        this.classpath = classpath;
    }

    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
       // 该方法是根据一个name加载一个类，我们可以使用一个流来读取path中的文件然后从文件中解析出class来
    }
    
}
```

调用defineClass（）方法加载类

```java
public static void main(String []args) throws ClassNotFoundException, InstantiationException, IllegalAccessException, NoSuchMethodException, SecurityException, IllegalArgumentException, InvocationTargetException{
        //自定义类加载器的加载路径
        MyClassLoader myClassLoader=new MyClassLoader("D:\\lib");
        //包名+类名
        Class c=myClassLoader.loadClass("com.test.Test");
        
        if(c!=null){
           // 做点啥
        }
    }
```

# 总结

本文从比较基础的层面解读了我们频繁使用却大部分人不是很了解的两个知识点——spi和jar机制。希望大家看完这篇文章后能对springboot中的一些“黑魔法”有更深入的了解，而不是停留在表面。

