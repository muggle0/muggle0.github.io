---
title: java8函数式编程
date: 2019-05-07 11:23:39
tags: developing
---

# 什么是函数式编程

方法参数化

## 函数式接口

只有一个方法的接口，在java中为了规范用 @FunctionalInterface 标注

lambda 表示函数式接口 ：

```java
Runnable runnable=()->{
    System.out.println("test");
};
```

核心思想就是尽量简化，没必要写的不写，实现的相关技术：类型推断

方法参数化的另外一种体现：

```java
Student::goHome;

System.out.println;
```

<!--more-->

## 

