---


title: 设计模式——单例模式
date: 2019-08-30 20:06:55
tags: 设计模式
---

单例模式 （Singleton Pattern）使用的比较多，比如我们的 controller 和 service 都是单例的，但是其和标准的单例模式是有区别的。这种类型的设计模式属于创建型模式，它提供了一种创建对象的最佳方式。这种模式涉及到一个单一的类，该类负责创建自己的对象，同时确保只有单个对象被创建。这个类提供了一种访问其唯一的对象的方式，可以直接访问，不需要实例化该类的对象。

<!--more-->

## 模式结构

单例模式的结构很简单，只涉及到一个单例类，这个单例类的构造方法是私有的，该类自身定义了一个静态私有实例，并向外提供一个静态的公有函数用于创建或获取该静态私有实例。

## 源码导读

单例模式分为懒汉单例和饿汉单例；饿汉单例代码很简单，顾名思义，饿汉单例就是类初始化的时候就将该单例创建，示例代码如下：

```java
public class Singleton {
	private static final Singleton singleton = new Singleton();
	//限制产生多个对象
	private Singleton(){	
	}
	//通过该方法获得实例对象
	public static Singleton getSingleton(){
		return singleton;
	}
	//类中其他方法，尽量是 static
	public static void doSomething(){
	}
}
```

但是懒汉单例就不那么简单了，懒汉单例是在访问这个类的实例的时候先判断这个类的实例是否创建好了，如果没创建好就要先创建这个单例。也就是说懒汉单例是第一次访问的的时候创建单例，而不是初始化阶段。这将会导致一个问题，如果在多线程场景下，多个线程同时访问这个单例都发现其未被创建，那么这些线程就会分别创建实例，那么这个单例模式就不那么单例了——实例被多次创建。在阿里开发手册中有两条就是和懒汉单例相关的，告诉我们要如何去避免这种情况，第六节的第一条 和第十二条：

> (六)并发处理
>
> 1.【强制】获取单例对象需要保证线程安全，其中的方法也要保证线程安全。 
>
> 说明：资源驱动类、工具类、单例工厂类都需要注意。 
>
> 12. 【推荐】在并发场景下，通过双重检查锁（double-checked locking）实现延迟初始化的优 
>
> 化问题隐患(可参考 The "Double-Checked Locking is Broken" Declaration)，推荐解 
>
> 决方案中较为简单一种（适用于 JDK5 及以上版本），将目标属性声明为 volatile 型。 
>
> 反例： 
>
> ```java
> class Singleton {  
> 	private Helper helper = null;  
> 	public Helper getHelper() {  
> 		if (helper == null) synchronized(this) {  
> 			if (helper == null)  
> 			helper = new Helper();  
> 		}  
> 		return helper;  
> 	}  
> // other methods and fields...  
> 
> } 
> ```

`volatile `关键字的作用和双重检查锁在我以往的博客中介绍过，文章地址`https://mp.weixin.qq.com/s/r52hmD71TtiJjlOzQUvRlA` 这篇博客介绍了并发的一些知识，小伙伴有空可以读一读。在这里 `volatile`  关键字的作用就是保证数据的可见性，双重检查锁是提高代码性能。下面我们分析一下手册中的反例：

其中它的双重检测锁指的是这段代码：

```java
if (helper == null) synchronized(this) {  
			if (helper == null)  
			helper = new Helper();  
		}  
```

这里如果不用双重检测锁的话只能在整个` getHelper` 方法上上锁，因为这个方法必须要保证在并发情况下只有一个线程会执行`helper = new Helper(); `，这段代码。也就是说代码 会成为这样：

```java
public synchronized Helper getHelper() {  
		if (helper == null)  {  
			if (helper == null)  
			helper = new Helper();  
		}  
		return helper;  
}  
```

整个方法上锁性能明显是不好的，锁的粒度变大了；双重检查锁里面为什么要做两次 if 判断呢，这个问题留给读者思考，并不是特别难的问题。但是反例里面没有考虑到可见性的问题——假设a线程和b线程同时访问 `getHelper` 方法，然后 b 线程被阻塞住，a线程发现`helper` 未被实例化，于是执行new方法，然后释放锁；此时b线程进来，或许我们直观的感受是b线程发现属性被实例化直接返回`helper`，但实际上不是，当一个线程修改了线程共享的公共资源的时候（此处是helper属性）其他线程未必会被通知到属性被修改，因此b线程有可能发现 `helper` 还是null 也有可能b线程知道 helper 被赋值了。使用`volatile` 就可以避免这种情况的发生。因此正确的代码应该是这样的：

```java
class Singleton {  
	private volatile Helper helper = null;  
	public Helper getHelper() {  
		······
	}  
// other methods and fields...  
} 
```

## 扩展

单例模式到这里算是讲完了，我再扩展一下单例相关的知识点——问：service 和 controller 都是单例的，它们的代码也没有锁相关的东西，为什么是线程安全的？

如果你jvm模型理解的还算透彻的话，这个问题就很好回答。通俗的说就是 service 或者 controller 里面都是方法，没有基本数据类型和字符串这样的属性。用专业术语回答就是：它们都是无状态的bean。其实bean的概念是在ejb规范里面提出来的，后面就被沿用了。感兴趣的小伙伴可以去查查资料，了解一下ejb规范里面的三种类型的bean。这里说一下什么是无状态的bean，什么是bean的状态。

有状态就是有数据存储功能。有状态对象(Stateful Bean)，就是有实例变量的对象，可以保存数据，是非线程安全的。在不同方法调用间不保留任何状态。无状态就是一次操作，不能保存数据。无状态对象(Stateless Bean)，就是没有实例变量的对象.不能保存数据，是不变类，是线程安全的。其中道理相信小伙伴们能想明白，不在再细说。