---
title: jenkins-3 Ansible和Jenkins
date: 2022-03-08 17:50:00
tags:
---

## 什么是Ansible
ansible是一个基于python的自动化运维工具，实现了批量系统配置、批量程序部署、批量运行命令等功能。ansible包括部署和使用简单、默认使用ssh协议、轻量级等特点。

ansible 架构：

![](/images/2022-04-17-20-11-11.png)

![](/images/2022-04-17-20-14-28.png)

https://www.cnblogs.com/keerya/p/7987886.html

懒得写

jenkins 内置四种构建触发器：

- 触发远程构建
- 其他工程构建后触发
- 定时构建
- 轮询scm

此外还可以通过安装插件通过git hook 自动触发构建

### 触发远程构建方式

我们可以通过访问jenkins 提供的链接触发jenkins流水线进行构建，如图所示：
![](/images/2022-04-17-21-46-24.png)
配置好令牌后访问地址：

```
http://localhost:9901/job/test2/build?token=test
```
再控制台上就能看到一次构建记录

### 其他工程构建后触发

当其他流水线执行后，触发当前流水线执行，如图所示：
![](/images/2022-04-17-21-51-15.png)

从图中我们能看到它的触发规则有四种

### 定时构建

即Build periodically，它通过cron表达式定时执行我们的流水线，如图所示：
![](/images/2022-04-17-21-55-21.png)

点击标题旁边的问号图标，Jenkins会给予相关的说明和示例，我们照着示例去配置即可，配置示例：

```
# Every fifteen minutes (perhaps at :07, :22, :37, :52):
H/15 * * * *
# Every ten minutes in the first half of every hour (three times, perhaps at :04, :14, :24):
H(0-29)/10 * * * *
# Once every two hours at 45 minutes past the hour starting at 9:45 AM and finishing at 3:45 PM every weekday:
45 9-16/2 * * 1-5
# Once in every two hour slot between 8 AM and 4 PM every weekday (perhaps at 9:38 AM, 11:38 AM, 1:38 PM, 3:38 PM):
H H(8-15)/2 * * 1-5
# Once a day on the 1st and 15th of every month except December:
H H 1,15 1-11 *
```

### 轮询scm
定时去扫描流水中配置的代码仓库，检测是否有变更，如果代码有变更则触发流水线执行，我们需要配置轮询规则，配置方式和定时构建一样：
![](/images/2022-04-17-22-02-03.png)

### git hook 自动触发构建

以github 为例，当github 发生代码提交的时候，github向jenkin 发送构建请求以执行流水线。

在github 上配置token并设置webhook:
登录github 访问链接https://github.com/settings/tokens，点击Generate new token,配置权限 repo,admin:repo_hook：
![](/images/2022-04-17-22-34-29.png)
点击保存，获取 token,保存好这个token

在github对应的代码仓库中选择设置-->webhooks
![](/images/2022-04-17-22-41-16.png)

在jenkins中安装github 插件，我们需要对插件进行一些配置以实现相关功能，配置界面如图所示：
![](/images/2022-04-17-22-27-30.png)
填写 API URL为https://api.github.com
点击添加按钮，类型选择Secret Text
![](/images/2022-04-17-22-47-08.png)
Secret 填token，其余随意。
然后在流水线的构建触发器中勾选GitHub hook trigger for GITScm polling 就ok拉：
![](/images/2022-04-17-22-48-57.png)


