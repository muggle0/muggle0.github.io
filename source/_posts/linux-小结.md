---
title: linux 小结
date: 2022-01-26 15:22:17
tags:
---

## linux 基本命令

1. 目录操作

- mkdir 创建文件夹
- mkdir -p 递归创建目录
- 创建多个目录 mkdir [-p] a b c
- touch  a b c 创建文件
- rm -r 递归 -f 强制删除
- cp -r 递归 复制 cp -r a/ b/
- mv 移动（重命名）
- ls （ll=ls -l）

2. 压缩

- gzip a.txt a.txt.gz
- gunzip a.txt.gz
- tar -c 创建 -x 解包 -v 可视化解压过程 -f 文件名 -z 压缩为gz -J xz格式

3. 输出重定向

```
> 标准输出重定向 覆盖输出
>> 追加输出重定向
```

3. 查看文件

- cat -n 显示行号
- tac
- head  查看文件前n行 默认10 head -n xxx.txt 
- wc -l 行数  -w 单词数 -c char
- 


``` 
## 从第3行开始显示，显示接下来10行内容: 
cat filename | tail -n +3 | head -n +10

## 过滤 -A 后n行 -B 前n行
cat test.log |grep 'xxx' -A10 -B10
## 按日期查日志
sed -n "/2022-01-14 15:05:55/,/2022-01-14 15:15:55/p" test.log
## 统计行数
wc -l file

```

4. 磁盘操作
 
- 查询子级目录的大小 `du -h --max-depth=1 /`
- 查询磁盘情况 `df -h /`
- find -type ( d 文件夹 f 文件) -name: `find / -name root -type d` `find / -name test.log`

5. 日期

- date date "+%F" date "+%F %T"
- timedatectl
- ntpdate

6. 管道

管道一般用于过滤， A|b 命令A的正确输出作为命令B的操作对象

grep 取出含有搜寻内容的行 -v 反选，：

```
## tail 出有关键字的日志并输出后10行
tail -f -n200 test.log|grep '出账' -A10
```

7. 其他

- killall
- ifconfig
- netstat -tnlp  net状态
- top 后  M 内存排序 P cpu 排序


8. linux 运行级别
   
- systemctl poweroff 关机
- systemctl rescue 单用户模式
- systemctl isolate multi-user.target 命令模式
- systemctl get-default

9. nohup
nohup命令用于不挂断地运行命令（关闭当前session不会中断改程序，只能通过kill等命令删除）.

```
# 将错误输出 标准输出丢弃
nohup test.jar >/dev/null 2>&1 &

# 将错误输出输出到屏幕，标准输出丢弃
nohup test.jar >/dev/null 2>&1 &
```


10. 计划任务

- at 一次性计划任务
- systemctl status atd
- at now +1minutes

- cron 周期性计划任务
- crond   
- crontable

使用crontable 创建任务后任务会记录到/var/sponl/cron里面去
执行日志保存到/var/log/cron中

```
##  这里，我们在每天早上 8 点整执行 find 命令；该命令会在 /home/s/coredump 目录下寻找 search 用户创建的普通 7 天前的文件，然后删除
 0 8 * * * find /home/s/coredump -user search -type f -mtime +7 -delete
```


11.   文件传输

scp [-P22 端口号] local_file remote_username@remote_ip:remote_file 

```
sudo scp -o xxx xxx.jar root@192.168.1.1:/home/test
```

12.  日志

- rsyslog -linux 日志系统  /etc/rsyslog.conf
- 日志切割 cronolog 

13. 网络设定

- nmcli
- 网络配置文件 :/etc/sysconfig/network-scripts/
- nmcli device status  查看网络连接
- nmcli device show 查看网络设备

## shell

1. #!/bin/sh是指此脚本使用/bin/sh来解释执行，#!是特殊的表示符，其后面根的是此解释此脚本的shell的路径。

2. 变量

- var1="xxx"
- $0 表示获取当前执行的shell脚本文件名，$n 表示获取当前执行的shell脚本的第n个参数值 $# 获取当前shell命令行中参数的总个数，$? 表示获取执行上一个指令的返回值（0为成功，非0为失败）
- 变量截取 ${变量名:起始位置:截取长度}

3. 表达式

-  test 条件表达式
-  [ 条件表达式 ]
-  命令1  &&  命令2 短路判断（如果命令1执行成功，那么我才执行命令2）
-  -f 表示是否是文件， -d 表示是否是目录，-x表示是否可执行

4. 循环和条件分支

```
if [ 条件 ]
then
  	指令
fi

if [ 条件 ]
then
  	指令1
else
 	指令2
fi

if [ 条件 ]
then
  	指令1
elif [ 条件2 ]
then
 	指令2
else
 	指令3
fi

case 变量名 in
   值1)
      指令1
         ;;
   ...
   值n)
 	   指令n
         ;;
esac

for 值 in 列表
do
   执行语句
done

while 条件
do
   执行语句
done

continue	跳出当前循环
exit		退出程序
```

5. 函数

```
#!/bin/bash
# 函数使用场景一：执行频繁的命令
dayin(){
  echo "wo de mingzi shi  111"
}
dayin

#!/bin/bash
# 函数的使用场景二
dayin(){
  echo "wo de mingzi shi $1"
}
dayin 111

#!/bin/bash
# 函数传参演示
# 定义传参数函数
dayin(){
  echo "wode mignzi shi $1"
}
# 函数传参
dayin $1

#!/bin/bash
# 函数的使用场景二
canshu = "$1"
dayin(){
  echo "wo de mingzi shi $1"
}
dayin "${canshu}"
```

## systemctl

用于配置开机自启动或者挂掉重启

配置示例：

```
[Unit]
Description=mongodb
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/xx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/xxx
PrivateTmp=true
Restart=always
RestartSec=5
```
其中配置 `Restart=always` 和 `RestartSec=5` 可在进程挂了之后重启,`systemctl daemon-reload` 重新加载配置。

Type：定义启动时的进程行为。它有以下几种值。

- Type=simple：默认值，执行ExecStart指定的命令，启动主进程
- Type=forking：以 fork 方式从父进程创建子进程，创建后父进程会立即退出
- Type=oneshot：一次性进程，Systemd 会等当前服务退出，再继续往下执行
- Type=dbus：当前服务通过D-Bus启动
- Type=notify：当前服务启动完毕，会通知Systemd，再继续往下执行
- Type=idle：若有其他任务执行完毕，当前服务才会运行

