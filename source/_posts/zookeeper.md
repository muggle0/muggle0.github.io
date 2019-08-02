---
title: zookeeper
date: 2019-06-15 17:23:46
tags: 中间件
---

# zookeeper 浅解

## ZK的安装与尝鲜

从官网 https://apache.org/dist/zookeeper/zookeeper-3.5.5/ 上下载zk(注意windows也是下载 tar.gz后解压)，./conf下有个`zoo_sample.cfg` 复制到同目录下改名为`zoo.cfg`，在目录下新建data和log文件夹，修改zoo.cfg中的 dataDir 和 `dataLogDir `为 data和log的路径。现在启动zk，在bin目录下有个`zkServer.cmd`，运行启动。启动ZK客户端对ZK进行简单的读写操作，在bin目录下打开cmd，运行：

<!--more-->

```cmd
./zkCli.cmd 127.0.0.1:2181
```

运行客户端连接上zk后我们可以在客户端cmd窗口输入一些指令来操作zk：

```shell
# ls 查看命令(默认只有根节点和zookeeper一个节点)
ls /
ls /zookeeper
#get 获取节点数据和更新信息
get /zookeeper
# stat 获得节点的更新信息
stat /zookeeper
# create -e 创建临时节点
create -e /a/b
# set path data [version] 修改节点
# 修改节点内容为sss
set /a sss
# delete path [version] 删除节点
# delete /a/b
```

通过操作部分指令我们看到，zk提供了对数据的增删改查。

