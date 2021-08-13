---
title: tcc推导
date: 2020-08-13 10:09:47
tags: cloud
---

## 事件的起因

最近在做一个项目，这个项目很有特点——它是一个分布式项目但是它却未使用分布式事务。我分析其事务机制和缺陷时，突然灵感一来，于是有了这篇文章。

## spring事务传播行为
在讨论分布式事务之前，我们先把spring事务传播机制过一遍，文章参考自[事务传播行为详解](https://segmentfault.com/a/1190000013341344#articleHeader11) 这位大佬写的很用心，文末评论区还讲到了一个关于spring事务的一个很重要的特性。spring事务传播行为有七种：


| 事务传播行为类型          | 说明                                                         |
| ------------------------- | ------------------------------------------------------------ |
| PROPAGATION_REQUIRED      | 如果当前没有事务，就新建一个事务，如果已经存在一个事务中，加入到这个事务中。这是最常见的选择。 |
| PROPAGATION_SUPPORTS      | 支持当前事务，如果当前没有事务，就以非事务方式执行。         |
| PROPAGATION_MANDATORY     | 使用当前的事务，如果当前没有事务，就抛出异常。               |
| PROPAGATION_REQUIRES_NEW  | 新建事务，如果当前存在事务，把当前事务挂起。                 |
| PROPAGATION_NOT_SUPPORTED | 以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。   |
| PROPAGATION_NEVER         | 以非事务方式执行，如果当前存在事务，则抛出异常。             |
| PROPAGATION_NESTED        | 如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则执行与PROPAGATION_REQUIRED类似的操作。 |


为了大家便于理解方便阅读我对原文做了总结，在这里我们讲三种事务的场景：

- 包含性事务：外部事务包含了内部事务组成一个统一的事务（REQUIRED）
- 挂起性事务：外部事务和内部事务只是在一起执行，互不影响（REQUIRES_NEW）
- 嵌套性事务：外部事务影响内部事务，内部事务不影响外部事务 （NESTED）


下面根据参考文章中的例子来一一说明

### 包含性事务

代码示例：
```java
   
    @Transactional(propagation = Propagation.REQUIRED)
    public void test1(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addRequired(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        user2Service.addRequired(user2);
        
        throw new RuntimeException();
    }
    
       
    @Transactional(propagation = Propagation.REQUIRED)
    public void test2(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addRequired(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        user2Service.addRequiredException(user2);
    }
    
    @Transactional

    public void test3(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addRequired(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        try {
            user2Service.addRequiredException(user2);
        } catch (Exception e) {
            System.out.println("方法回滚");
        }
    }

```
上述代码中`user1Service.addRequired(user1)` 是一个 “正常” 的 insert 事务，` user2Service.addRequiredException(user2)` 是一个抛异常的事务。这三个方法都会发生回滚。以`test3()` 为例， `user1Service.addRequired(user1)`正常提交后外部的事务（`test3()` 所在的事务 ）发生了回滚，这个事务也会跟着回滚，这便是包含关系。

## 挂起性事务

挂起性事务，是外部事务和内部事务互不干扰，两者只能通过抛出异常来交互（后面分布式项目分析中就是和这种事务一样）。示例：

```java
    @Transactional(propagation = Propagation.REQUIRED)
    public void test1(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addRequired(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        user2Service.addRequiresNew(user2);
        
        User2 user3=new User2();
        user3.setName("王五");
        user2Service.addRequiresNewException(user3);
    }
    
    @Transactional(propagation = Propagation.REQUIRED)
    public void test2(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addRequired(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        user2Service.addRequiresNew(user2);
        User2 user3=new User2();
        user3.setName("王五");
        try {
            user2Service.addRequiresNewException(user3);
        } catch (Exception e) {
            System.out.println("回滚");
        }
    }
```

上述代码中 ` user1Service.addRequired(user1)` 和外部事务是包含关系；`user2Service.addRequiresNew(user2)` 是挂起事务；`user2Service.addRequiresNewException(user3)` 是挂起并将会执行失败的事务。test1 方法中由于外部事务是包含事务，因此` user2Service.addRequiresNewException ` 异常会导致 `user1Service.addRequired` 回滚 而由于`user2Service.addRequiresNew` 是挂起事务它不会回滚。在test2 中由于 test2 捕获了异常所以不会触发外部事务的回滚，`user1Service.addRequired` 和 ` user2Service.addRequiresNew` 均能执行成功；但是要注意一个情况，假如 `user2Service.addRequiresNewException(user3)` 这个方法加了包含性事务的注解（既 `@Transactional(propagation = Propagation.REQUIRED)` ） 的情况下，虽然在外部事务中try catch 了，但其方法本身所在的事务发生了回滚，该子事务回滚之后会将整个事务标记位记为`rollbackOnly`,当外部事务发现事务被标记为 `rollbackOnly` 时不会提交，而是回滚。

## 嵌套性事务

该事务如果内部事务回滚，不会触发外部事务的回滚，但外部事务的回滚会导致内部事务回滚。下面看示例：
```java
    @Transactional
    public void test1(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addNested(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        user2Service.addNested(user2);
        throw new RuntimeException();
    }
    
    
    @Transactional
    public void test2(){
        User1 user1=new User1();
        user1.setName("张三");
        user1Service.addNested(user1);
        
        User2 user2=new User2();
        user2.setName("李四");
        try {
            user2Service.addNestedException(user2);
        } catch (Exception e) {
            System.out.println("方法回滚");
        }
    }
```
在test1 中外部事务回滚，导致嵌套事务回滚，`user1Service.addNested` 和 `user2Service.addNested(user2);` 均回滚了，在test2 中，`user2Service.addNestedException(user2)` 这个嵌套事务回滚了，但外部事务不会回滚 因此 `user1Service.addNested(user1)`不会回滚。在挂起性事务中我们提到`rollbackOnly`标志位，在test2里也是一样，如果
` user2Service.addNestedException(user2)` 是一个抛异常的包含性事务，其外部事务也会回滚，既 `user1Service.addNested` 会回滚。

## spring事务总结

为了下文能便于理解，我们先做个简单的总结，其实spring事务按顺序排下来就分四种情况：
1. 无事务，禁止外部使用事务
2. 内部事务和外部事务互相影响
3. 外部事务影响内部事务，但是内部事务不影响外部事务
4. 外部事务和内部事务互不影响

## 分布式系统中的事务

假设我们在分布式系统中使用普通的本地事务会怎么样呢（作者运气比较好，不需要假设，实际场景就是）？ 下面我们来分析一段伪代码
```java

    @Transactional
    public void test1(){
        rpcService.update();
        localService.update();
        if（“业务逻辑判断”）{
             throw new RuntimeException();
        }
        
    }

```
`rpcService.update()` 是一个更新数据库的rpc方法，`localService.update()` 是一个更新数据库的本地方法。为了简化模型，我们认为两个方法操作的是同一个数据库。这个方法执行会发生什么呢？很明显，这里相当于一个挂起性事务，rpcService都夸虚拟机了，自然不会被本地spring的事务所管控，相当于两个事务放在一起互不相干。该方法将会导致，`rpcService.update()`写入脏数据，而 `localService.update()` 会回滚，这是很糟糕的情况。如果`rpcService.update()` 抛出异常还好，还能让事务回滚，要是正常执行就完犊子了。我们要怎么去避免呢？最笨的办法是 我们调用rpc的service时只执行查询语句。所有更新数据库的操作全部在本地执行。但这种方式不是任何情况都适用，有的时候我们不得不去 rpc update。那么在没有引入分布式中间件的时候怎么去实现一个分布式事务？一种方式是通过 mysql的 `XA` 分布式事务机制，这种方式缺点也是很明显的，首先 `XA` 在5.6以上版本才适用，其次它很耗资源。我们考虑一下有没有通过代码或者结构设计的方式来实现数据一致。我们可以要 `rpcService.update()` 的事务卡在那不commit，等`localService.update()` commit 了再让它commit，这样又有问题了，如果卡住 `rpcService.update()` 的事务那么，这个方法就会阻塞，只能开启异步线程来让它在后台挂起，异步又会导致该方法必须是void的，这又是很难做到的事情——必须要所有rpc方法都无返回值。

## tcc的产生

上面几种思路貌似都不是很理想，虽然能实现但效果必定不会很好，有没有别的办法？我们回过头来分析开始那段伪代码，这段代码存在的问题是如果本地方法回滚了，rpc的方法会产生脏数据。那如果脏数据能在后续步骤清除并且这部分脏数据不会影响正常业务呢？我可以在本地方法rollback的时候清除它，而且正常的业务代码也不会被它影响。我们都知道不少企业在设计数据库的时候，对数据的删除不是使用物理删除，而是使用逻辑删除，被逻辑删除的数据也不会影响正常业务的运行，而被删除的数据实际上还保存在数据库，只是将删除标识标记为1,表示已删除。

基于上述原理，我们可以整个逻辑提交这个概念——在数据库中专门准备一个字段`commited` 0 表示虽然写入库，但是未被commit 属于“脏数据”，1 是已经commited 可以被业务代码读写的数据。那上面的代码也要改一下：
```
@Transactional
    public void test1(){
        rpcService.updateNotCommit();
        localService.update();
        if("业务逻辑正确，可以commit"){
            rpcService.commit();
        }else(){
            System.out.print("业务错误，需要回滚")
            rpcService.rollBack();
            throw new RuntimeException();
        }
       
    }
```

上述设计方式，似乎解决了我们的问题，但只是理想状态下不会出错；不理想的状态下，可能发生网络波动，` rpcService.rollBack()` 请求未抵达抛出异常，那么数据库里面会堆积不少脏数据，虽然对业务没影响，但是很影响性能。而且如果有多个commit，比如这样：
```
@Transactional
    public void test1(){
        rpcService.updateNotCommit0();
        rpcService.updateNotCommit1();
        rpcService.updateNotCommit2();
        localService.update();
        if("业务逻辑正确，可以commit"){
            rpcService.commit0();
            rpcService.commit1();
            rpcService.commit2();
        }else(){
            System.out.print("业务错误，需要回滚")
            rpcService.rollBack();
            throw new RuntimeException();
        }
       
    }
```
假设`rpcService.commit2()` 发生网络波动，未发出请求抛出异常，那么会发生`commit0` 成功 `commit1` 成功，本地事务失败，`commit2`失败。这样就又产生影响业务的脏数据了。这种情况证明办？我们需要一个机制来能在commit或者rollback请求未发送出去的时候去重试，保证能够发送请求出去。因此我们要保证 commit 或者 rollback 不能抛异常，并且能够去请求失败的时候重试。重试很好实现，做一个标志位和计数器当请求成功的时候改变标志位状态，计数器计数重试次数，超过次数就通过某种机制来通知到运维人员需要去检查什么地方出了问题，手动对数据提交或者回滚。

推导到这一步好像这个思路要做的事情还比较多了，而且这个功能通用性也挺强，要不整成中间件吧，这个中间件有重试机制，错误通知机制；物理commit，逻辑commit ，逻辑rollback的请求接口。对于这三个接口的注册方法我们可以用注解或者实现接口的方式，通过aop来获取其注册到这个中间件的接口。然后我们需要使用分布式事务的时候先从中间件拿到这个事务的三个接口，而事务的执行方提供这三个接口。

嗯，这个套路研究到这里好像还蛮牛掰的，要不咱们取个响亮点的名字吧——就叫TCC好了
