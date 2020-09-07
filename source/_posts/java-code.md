---
title: java-code
date: 2020-09-07 14:58:05
tags:
---


# 操作码介绍

我们都知在Java中我们的类会被编译成字节码然后放到虚拟机中去执行，字节码里面的内容其实我们也是可以去“阅读”的，方法就是通过 jdk自带的工具翻译成操作码。在操作码中我们能看到一些我们平时看不到的关于java的秘密。

Java虚拟机的指令由一个字节长度的的数字以及跟随其后的零至多个代表此操作所需的参数构成。即：Java指令 = 操作码 + 操作数。Java虚拟机本身是采用面向操作数栈而不是寄存器的架构，所以大多数的指令都不包含操作数，只有一个操作码。通过阅读操作码我们能直观的看到一些方法的执行过程。

<!--more-->

## 查看操作码
我们随便找一个 .class 文件(我这里是Test.class)，然后在命令行执行:

```java
javap -v -l -p -s -sysinfo  -constants Test.class
```
`Test.java` 源码为：

```java
public class Test {
    private String a;
    private static final String STR="hello word";
    public static void main(String[] args) {
        System.out.println(STR);
    }
}

```

执行指令后可在命令行窗口看到:
```java
Classfile /G:Test.class
  Last modified 2020-8-9; size 585 bytes
  MD5 checksum 09bb7ece9c879902984714504494a9e3
  Compiled from "Test.java"
public class Test
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #6.#24         // java/lang/Object."<init>":()V
   #2 = Fieldref           #25.#26        // java/lang/System.out:Ljava/io/PrintStream;
   #3 = Class              #27            // Test
   #4 = String             #28            // hello word
   #5 = Methodref          #29.#30        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #6 = Class              #31            // java/lang/Object
   #7 = Utf8               a
   #8 = Utf8               Ljava/lang/String;
   #9 = Utf8               STR
  #10 = Utf8               ConstantValue
  #11 = Utf8               <init>
  #12 = Utf8               ()V
  #13 = Utf8               Code
  #14 = Utf8               LineNumberTable
  #15 = Utf8               LocalVariableTable
  #16 = Utf8               this
  #17 = Utf8               LTest;
  #18 = Utf8               main
  #19 = Utf8               ([Ljava/lang/String;)V
  #20 = Utf8               args
  #21 = Utf8               [Ljava/lang/String;
  #22 = Utf8               SourceFile
  #23 = Utf8               Test.java
  #24 = NameAndType        #11:#12        // "<init>":()V
  #25 = Class              #32            // java/lang/System
  #26 = NameAndType        #33:#34        // out:Ljava/io/PrintStream;
  #27 = Utf8               Test
  #28 = Utf8               hello word
  #29 = Class              #35            // java/io/PrintStream
  #30 = NameAndType        #36:#37        // println:(Ljava/lang/String;)V
  #31 = Utf8               java/lang/Object
  #32 = Utf8               java/lang/System
  #33 = Utf8               out
  #34 = Utf8               Ljava/io/PrintStream;
  #35 = Utf8               java/io/PrintStream
  #36 = Utf8               println
  #37 = Utf8               (Ljava/lang/String;)V
{
  private java.lang.String a;
    descriptor: Ljava/lang/String;
    flags: ACC_PRIVATE

  private static final java.lang.String STR = "hello word";
    descriptor: Ljava/lang/String;
    flags: ACC_PRIVATE, ACC_STATIC, ACC_FINAL
    ConstantValue: String hello word

  public Test();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 1: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   LTest;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #4                  // String hello word
         5: invokevirtual #5                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
         8: return
      LineNumberTable:
        line 5: 0
        line 6: 8
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       9     0  args   [Ljava/lang/String;
}
```
有的小伙伴可能没有将 jdk的bin目录配置到环境变量，执行`javap`指令的时候识别不了该指令，我们只需要指定指令的全路径就ok了，比如我的 bin 目录是 `C:\jdk\bin` 那我的指令就是 `C:\jdk\bin\javap.exe -v -l -p -s -sy、sinfo  -constants Test.class`。javap 指令的参数含义可以通过 `javap -help`查看 这里不多做介绍。

## 操作码阅读指南

通过命令行窗口输出的内容分为以下几个部分：
- Classfile 是一些类信息，
- Constant pool 是编译时常量池，`Constant pool` 中我们能看到方法信息、变量信息、关键字信息等，
- {} 里面的内容是方法的一些执行指令。

我们将字节码文件翻译成了操作码，里面的信息量很大，别着急，我们一点点的去解读。Classfile部分是一些类信息，这一部分不是我们研究的重点，因此我这里不做太多介绍。
阅读操作码我们需要去查阅操作码指令表，在网上就能搜到。我在这里罗列一些比较重要的操作码。

数据类型相关

- iload指令用于从局部变量表中加载int型的数据到操作数栈中；
- fload指令则是从局部变量表中加载float类型的数据到操作数栈中；
- i代表int类型，l代表long类型，s代表short类型，b代表byte类型，a代表reference类型；以此类推

加载和存储指令相关

- 将一个局部变量加载到操作数栈，有iload、iload_<n>、lload、lload_<n>、aload、aload_<n>等
- 将一个数值从操作数栈存储到局部变量表，有istore、istore_<n>、lstore、lstore_<n>、astore、astore_<n>等
- 将一个常量加载到操作数栈，有bipush、sipush、ldc、aconst_null、iconst_<i>等

运算指令相关

- 加法指令 iadd、ladd、fadd、dadd，
- 减法指令 isub、lsub、fsub、dsub，
- 乘法指令 imul、lmul、fmul、dmul，
- 除法指令 idiv、ldiv、fdiv、ddiv，
- 求余指令 irem、lrem、frem、drem
- 取反指令 ineg、lneg、fneg、dneg
- 位指令 ior、lor 是或运算，iand、land 是与运算 ixor、lxor 是异或运算
- 其他 iinc 是自增运算 dcmpg、dcmpl、fcmpg、fcmpl、lcmp 是比较运算

操作数栈指令
- 出栈指令 pop、pop2 
- 复制压栈 dup、dup2、dup_x1、dup2_x1、dup_x2、dup2_x2
- 将栈最顶端的两个数值互换 swap
- 条件分支 ifeq、iflt、ifle、ifne 
- 无条件分支 goto、goto_w、jsr、jsr_w、ret
- 复合条件分支tableswitch、lookupswitch

方法调用相关
- 方法返回值类型表示方式 ()V 表示 void 方法  ()Ljava/lang/String 表示 返回 String 类型，()I 表示返回int类型，以此类推
- invokevirtual指令用于调用对象的实例方法，
- invokeinterface指令用于调用接口方法，
- invokespecial指令用于调用一些需要特殊处理的实例方法
- invokestatic指令用于调用静态方法
- invokedynamic指令用于在运行时动态解析出调用点限定符所引用的方法
- athrow指令用来实现显式抛出异常的操作
- monitorenter和monitorexit两条指令来支持synchronized关键字的语义

## 操作码相关源码解读

前文提到过操作码可以看到 java 的一些秘密，下面我们由难到易解读几个案例。

**案例一 this 关键字的加载时机**

我们思考下面一段代码：

```java
public class Test {
    private String test;
    
    {
        System.out.println("执行动态代码块");
        this.test="执行动态代码块";
    }
    
    public Test(){
        System.out.println(test);
    }
}

```
这段代码相信有工作经验的朋友都研究过，但是现在我们不是来讨论代码的额执行顺序，而是讨论另外一个问题：为什么动态代码块里面可以用 this 关键字？ 我们思考一下，this代指当前对象，而构造函数还没有执行我们哪来的对象？那还没有对象，我们的this又指向谁？这是一个值得思考的问题。那我们来看看这段代码的操作码吧：

```java
 public Test();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
         7: ldc           #3                  // String 执行动态代码块
         9: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        12: aload_0
        13: ldc           #3                  // String 执行动态代码块
        15: putfield      #5                  // Field test:Ljava/lang/String;
        18: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
        21: aload_0
        22: getfield      #5                  // Field test:Ljava/lang/String;
        25: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        28: return
      LineNumberTable:
        line 9: 0
        line 5: 4
        line 6: 12
        line 10: 18
        line 11: 28
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      29     0  this   LTest;
```
我们仔细阅读发现，其实它的构造方法组成并不是我们在类里面看到的那样，第一步先执行 `aload_0` 然后 通过`invokespecial` 指令调用了 对象初始化方法 `<init>` ，然后再是正真的执行我们构造函数自己的逻辑。注意了，这里的 `aload_0` 就是加载this关键字，也就是其实动态代码块是直接编译在构造函数之中的，而且 this关键字的产生是对象产生的第一步；也就是说我们创建的对象从操作码的角度来讲，首先就是先加载一个 this 上来，然后再初始化对象，再实例化对象。

案例二 sychornized 关键字原理。

sychornized 从操作码的层面来观察是比较直观的，我们百度sychornized关键字原理的时候，通常是这么解释的：jvm基于进入和退出 `Monitor` 对象来实现方法同步和代码块同步，而这个 `Monitor` 是存储在Java对象头里的。
我们理解起来可能比较抽象，让我们读操作码来分析吧：

同步方法：
```java
    public static  void testSyn(int i){
        synchronized(Test.class){
            System.out.println(">>>>>>>>>>>>>>>>>");
        }
    }
```

对应的部分操作码：
```java
 public static void testSyn(int);
    descriptor: (I)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=3, args_size=1
         0: ldc           #6                  // class Test
         2: dup
         3: astore_1
         4: monitorenter
         5: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
         8: ldc           #7                  // String >>>>>>>>>>>>>>>>>
        10: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        13: aload_1
        14: monitorexit
        15: goto          23
        18: astore_2
        19: aload_1
        20: monitorexit
        21: aload_2
        22: athrow
        23: return
```
结合前文的操作码指令介绍，我们可以看到同步代码块的执行过程，先执行 monitorenter 指令获取锁，当获取锁成功，执行下面的指令，最后 monitorexit 释放锁，monitorenter 被jvm封装成一个完整指令，其执行原理就是前面所说的内容，而再往深究的话就是通过互斥原语（CPU lock 指令加 对象头锁标记位）来实现的。

案例三 对象初始化死锁。

这是一个很有意思的题，在b站上能搜到它的操作码分析视频，关键字  小马哥每日一问 2019.07.18 期 。我把题目贴出来，大佬们自己动手研究一下，阅后习题：

```java
public class Test {
  private static boolean initialized=false;
  
  static {
      Thread t=new Thread(()-> initialized=true);
      t.start();
      try {
          t.join();
      }catch (InterruptedException e){
          throw new AssertionError(e);
      }
  }

    public static void main(String[] args) {
        System.out.println(initialized);
    }
}

以上程序输出内容是？

1. true
2. false
3. 编译错误
4. 以上答案都不对

```
上面这个题目是很有意思的，小伙伴们仔细研究一下。