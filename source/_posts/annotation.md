---
title: 注解及其反射机制
date: 2019-05-15 16:53:32
tags: javase
---

# 注解相关知识

## 元注解

1. @Retention：生命周期，RetentionPolicy.SOURCE 注解只在源码阶段保留，RetentionPolicy.CLASS 注解只被保留到编译进行的时候，它并不会被加载到 JVM中，RetentionPolicy.RUNTIME 注解可以保留到程序运行的时候
2. @Documented：作用是能够将注解中的元素包含到 Javadoc 中去。
3. @Target：指定了注解运用的地方。ElementType.ANNOTATION_TYPE 可以给一个注解进行注解，ElementType.CONSTRUCTOR 可以给构造方法，ElementType.FIELD 可以给属性，ElementType.LOCAL_VARIABLE 可以给局部变量，ElementType.METHOD 可以给方法，ElementType.PACKAGE 可以给一个包，ElementType.PARAMETER 可以给一个方法内的参数，ElementType.TYPE 可以给一个类型进行注解，比如类、接口、枚举
4. @Inherited：一个超类被 @Inherited 注解过的注解进行注解的话，那么如果它的子类没有被任何注解应用的话，那么这个子类就继承了超类的注解。
5. @Repeatable ：可重复注解

<!--more-->

## 注解的属性

注解的属性也叫做成员变量。注解只有成员变量，没有方法。注解的成员变量在注解的定义中以“无形参的方法”形式来声明，其方法名定义了该成员变量的名字，其返回值定义了该成员变量的类型。

```java
public class BootStaterTestApplicationTests {
    @Test
    public void contextLoads() {
        @muggle(test = "ss")
        String test="ss";
    }
}

@Target(ElementType.LOCAL_VARIABLE)
@interface muggle{
    String test();
}
```

解中属性可以有默认值，默认值需要用 default 关键值指定。

```java
@Target(ElementType.LOCAL_VARIABLE)
@interface muggle{
    String test()default "test";
}
```

一些缺省写法略

## 反射获取注解

类注解

```java
		test test = new test();
        Class<? extends com.muggle.bootstatertest.test> aClass = test.getClass();
        Class<Muggle> muggleClass = Muggle.class;
        boolean annotationPresent = aClass.isAnnotationPresent(muggleClass);
        System.out.println(annotationPresent);
        Annotation[] annotations = aClass.getAnnotations();
        Muggle annotation = aClass.getAnnotation(Muggle.class);
```

属性注解

```java
Field[] fields = aClass.getFields();
Annotation[] annotations1 = fields[0].getAnnotations();
```

方法注解

```java
Method[] methods = aClass.getMethods();
Method[] declaredMethod = aClass.getDeclaredMethods();
Annotation[] declaredAnnotations = methods[0].getDeclaredAnnotations();
```

