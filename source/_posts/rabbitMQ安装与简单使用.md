---
title: rabbitMQ安装与配置
date: 2020-12-12
tags: 中间件
---

对 rabbitMQ 我们已经有了初步的了解，现在我们来安装 rabbitMQ 来进行一些操作。因为大部分人的操作系统都是windows 而且作者本人使用的也windows系统。所以这里只介绍在windows上安装rabbitMQ。mac用户自行解决（仇富脸）。
<!--more-->
## erlang的安装

erlang 不好的地方是它不是向下兼容的，也就是说 rabbitMQ的版本和erlang的版本不匹配的话，会安装失败。所以我们要先上 rabbitMQ的官方网站查询对应的版本号，再安装 网站：https://www.rabbitmq.com/which-erlang.html 

查询好版本后向erlang 官方网站下载安装程序，网址：http://www.erlang.org/downloads 

下载安装完成之后，配置erlang的环境变量（参考JAVA_HOME）。

```
变量名：ERLANG_HOME
变量值：你的安装路径
```

然后将  `%ERLANG_HOME%\bin` 加入到path中，和Java maven 这些程序的配置方式一样。然后在cmd 中输入 `erlang` 验证一下，完成。

## rabbitMQ的安装

下载地址：http://www.rabbitmq.com/download.html

注意要找对版本下载安装。安装完成后进入RabbitMQ的sbin目录下在cmd中执行

```
./rabbitmq-plugins enable rabbitmq_management
```

这个指令是安装 `rabbitmq_management` 插件。安装完成后cmd中执行（sbin目录下）：

```
./rabbitmqctl status 
```

可以看到rabbitMQ的一些信息，就说明rabbitMQ安装成功了。如果没有成功。检查一下版本和环境变量等信息，重新安装。

## rabbitMQ的配置

安装完成之后执行 sbin 下的 `rabbitmq-server.bat` 启动 rabbitMQ 访问 http://localhost:15672 。我们会看到一个登录界面。用户名和密码都是guest。登录进去后能看到一些交换机 队列 用户 等的信息。

![图 1：rabbit的web管理界面](https://raw.githubusercontent.com/muggle0/muggle0.github.io/master/a.png)

​										图 1：rabbit的界面

guest这个用户是只能本地访问rabbitMQ的，相当去 mysql 的 root 用户。下面我们配置一个可以远程使用的开发账号。

创建用户指令：

```
rabbitmqctl.bat add_user [username] [password]
## 示例
rabbitmqctl set_user_tag test test
```

查看用户列表：

```
rabbitmqctl list_users
```

给用户设置权限（tag）

```
rabbitmqctl set_user_tag [tag1] [tag2]
## 示例
rabbitmqctl set_user_tag test administrator 
```

rabbitMQ 有五个tag(权限) 分别是：

-  超级管理员(administrator) 有所有权限
-  监控者(monitoring) 有读权限
-  策略制定者(policymaker) 
-  普通管理者(management) 
- 其他（none）

配置完权限之后，我们再修改配置文件以支持新建账号的远程访问。我们打开 rabbitMQ安装目录的下的 `etc/rabbitmq.config.example` 搜索 `loopback_users` 会找到这一行：

```
  %% {loopback_users, []},
```

改成

```
{loopback_users, ["username0","username1"]},
```

这里的username 是你的用户名。配置完成后重启服务：

```
sbin/rabbitmq-service.bat stop
sbin/rabbitmq-service.bat start
```

---

作者：muggle [点我关注作者](https://muggle.javaboy.org/2019/03/20/home/) 

出处：https://muggle-book.gitee.io/

版权：本文版权归作者所有 

转载：欢迎转载，但未经作者同意，必须保留此段声明；必须在文章中给出原文连接；否则必究法律责任

