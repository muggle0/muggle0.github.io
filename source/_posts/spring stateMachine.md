---
title: spring 状态机
date: 2026-01-18 17:35:19
tags: spring
---

## 状态机介绍
我们在web 项目中讨论的状态机通常是指状态机这种设计模式。该设计模式属于行为型设计模式，

它允许对象在内部状态改变时改变其行为，看起来好像修改了自身的类。这种模式通过将状态相关的行为封装到不同的状态对象中，解决了复杂条件判断（如大量if-else或switch-case）导致的代码臃肿问题。
<!-- more -->
状态机设计模式的核心是将对象的状态封装为独立的状态类，每个状态类负责定义该状态下对象的行为，以及状态之间的转换逻辑。当对象的状态发生变化时，它会切换到对应的状态类，从而表现出不同的行为。

状态机的构成：

+ 状态机上下文，维护状态的流转与引用
+ 状态，定义具体的各个状态
+ 事件，触发状态变化

## 在springboot中使用状态机
为了更好的使用状态机，spring维护了一套框架 `spring stateMachine` 它主要有以下概念

+ State 状态，定义业务中各个状态标识
+ Event 事件，定义触发业务状态变换的事件标识
+ Action 动作，状态变化触发相应的动作
+ Transition 变换，指状态变化的某个具体过程

现在我们可以假设一个业务流程，有以下几步

1. 销售员联系客户，客户对销售员下单付费
2. 销售员建销售单，并通知相应负责人审核，销售单状态为待审批
3. 销售单审核通过，销售单状态为待出库，生成出库单，库管人员清点货品，签字确认出库单，出库单状态为待打包
4. 打包人员根据出库单打包货品，寄出货品，销售单状态为在途，出库单状态为完结
5. 客户收到货品，和销售员确认，销售员完成销售单，财务系统销售额入账，关闭销售单。

流程简图：

<!-- 这是一张图片，ocr 内容为： -->
![](/images/state.png)
我们分析这个业务中，有哪些状态，什么事件触发状态变化，触发哪些动作，有哪些变换

销售单的状态为待审批，待出库，在途，完结。事件为销售单审批，出库单确认，打包发货，客户确认收货。

触发的动作为通知负责人审批，生成出库单，通知库管，通知打包人员，通知客户，销售额数据传输至相关财务系统入账。

OK，一个简单的业务梳理完成，看看我们怎么去实现。

 状态机maven依赖：

```plain
<dependency>
    <groupId>org.springframework.statemachine</groupId>
    <artifactId>spring-statemachine-boot</artifactId>
    <version>1.2.9.RELEASE</version>
</dependency>

<dependency>
    <groupId>org.springframework.statemachine</groupId>
    <artifactId>spring-statemachine-core</artifactId>
    <version>3.2.0</version> <!-- 版本号可根据需要调整 -->
</dependency>
```

相关的类：

```plain
package com.muggle.machine.config;

public enum SaleStateEnum {
    CREATED,APPROVED,OUTBOUND,RECEIVED,
    OUT_CREATED,OUT_APPROVED,OUT_PACKED
}

```

```plain
package com.muggle.machine.config;

public enum SaleEventEnum {
    CREATE,APPROVE,OUT_APPROVE,PACK,SIGN_FOR
}


```

```plain


@Service
public class SaleRuntimeStateMachinePersister extends AbstractPersistingStateMachineInterceptor<SaleStateEnum, SaleEventEnum,String>
implements StateMachineRuntimePersister<SaleStateEnum,SaleEventEnum,String>{

    @Override
    public void write(StateMachineContext<SaleStateEnum, SaleEventEnum> stateMachineContext, String id) throws Exception {
        // todo 写入 销售单表的订单状态字段
    }

    /**
     * 此处id 是new 状态机时传入的值
     * @param id
     * @return
     * @throws Exception
     */
    @Override
    public StateMachineContext<SaleStateEnum, SaleEventEnum> read(String id) throws Exception {
        // todo 根据id 查找对应的销售单，读取状态字段 new 一个状态机上下文
        DefaultStateMachineContext<SaleStateEnum, SaleEventEnum> context = new DefaultStateMachineContext<>(SaleStateEnum.APPROVED, null, null, null, null, id);
        return context;
    }

    @Override
    public StateMachineInterceptor<SaleStateEnum, SaleEventEnum> getInterceptor() {
        return this;
    }
}

```

```plain
@Configuration
@EnableStateMachineFactory(name = "SaleStatemachineFactory")
public class SaleStatemachineFactory extends EnumStateMachineConfigurerAdapter<SaleStateEnum,SaleEventEnum> {

    @Autowired
    private SaleRuntimeStateMachinePersister persister;

    @Override
    public void configure(StateMachineConfigBuilder<SaleStateEnum, SaleEventEnum> config) throws Exception {
        super.configure(config);
    }

    @Override
    public void configure(StateMachineModelConfigurer<SaleStateEnum, SaleEventEnum> model) throws Exception {
        super.configure(model);
    }

    @Override
    public void configure(StateMachineConfigurationConfigurer<SaleStateEnum, SaleEventEnum> config) throws Exception {
       config.withPersistence().runtimePersister(persister);
    }

    @Override
    public void configure(StateMachineStateConfigurer<SaleStateEnum, SaleEventEnum> states) throws Exception {
        states.withStates().initial(SaleStateEnum.CREATED).states(EnumSet.allOf(SaleStateEnum.class))
                .end(SaleStateEnum.RECEIVED);
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<SaleStateEnum, SaleEventEnum> transitions) throws Exception {
        transitions.withExternal()
                .source(SaleStateEnum.CREATED).target(SaleStateEnum.APPROVED)
                .event(SaleEventEnum.APPROVE)
                .and().withExternal().source(SaleStateEnum.APPROVED).target(SaleStateEnum.OUTBOUND)
                .event(SaleEventEnum.OUT_APPROVE);
    }

}

```



```plain
@Service
public class SaleStatemachineService extends DefaultStateMachineService<SaleStateEnum,SaleEventEnum> {


    public SaleStatemachineService(StateMachineFactory<SaleStateEnum, SaleEventEnum> stateMachineFactory,
                                   StateMachinePersist<SaleStateEnum, SaleEventEnum, String> stateMachinePersist) {
        super(stateMachineFactory, stateMachinePersist);
        ObjectStateMachineFactory objfactory = (ObjectStateMachineFactory) stateMachineFactory;
        // 此处一定要重新设置名称，状态机框架的一个bug
        objfactory.setBeanName("SaleStatemachineFactory");
    }

    public void test(){
        StateMachine<SaleStateEnum, SaleEventEnum> stateMachine = this.acquireStateMachine("销售单id");
        stateMachine.sendEvent(SaleEventEnum.APPROVE);
        this.releaseStateMachine("销售单id");
    }
}

```

```plain
@WithStateMachine(name = "SaleStatemachineFactory")
public class SaleHandler {


    // 表示监听 销售单从创建到审批的变换
    @OnTransition(source = "CREATED",target = "APPROVED")
    public void test(StateContext<SaleStateEnum,SaleEventEnum> context){
        // 销售单的id
        String id = context.getStateMachine().getId();
        // todo 创建出库单
    }
    @OnTransition(source = "CREATED",target = "APPROVED")
    public void test1(StateContext<SaleStateEnum,SaleEventEnum> context){
        // 销售单的id
        String id = context.getStateMachine().getId();
        // todo 通知出库审批人
    }
}

```



很多状态机的demo 中是通过单例的方式去使用状态机的，这种用法明显是错误的，状态机是有状态的bean，既然是有状态的bean就不能单例使用，线程不安全。官方是提供了持久化模块的，但是对于有的项目来说，单独对状态机持久化有点过度使用了。所以我这里的示例用的是   `StateMachineRuntimePersister`来做了优化。



就写到这里啦，大家中秋节快乐。

