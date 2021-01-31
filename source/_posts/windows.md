---
title: windows使用技巧
date: 2019-05-01 10:04:45
tags: tool
---

**每次开机都启动一堆软件，很麻烦，该肿么办？**

写个批处理文件 步骤（这里以启动微信为例 ）：

1. 新建一个文本文档
2. 输入以下命令：

> start "xx" "xxx"

xx 代表程序名称，可以随便起；xxx代表你想启动的程序的位置 获取程序位置的方法：

<!--more-->

> 右击程序对应的桌面快捷方式，选择属性，其中的目标栏就是程序的位置了

![image](http://upload-images.jianshu.io/upload_images/13612520-236984bb739b0420?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

获得程序的位置信息

3.将.txt后缀改为.bat(你的电脑可能设置隐藏后缀，让它显示出来就行)

结果就像这样：

![image](http://upload-images.jianshu.io/upload_images/13612520-6aa760879ee20e25?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

编写程序启动命名

![image](http://upload-images.jianshu.io/upload_images/13612520-8af85a2b881eec7c?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image](http://upload-images.jianshu.io/upload_images/13612520-74ed965c7bb7ad54?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

修改文件后缀

点击一下就可以启动微信了，想一次性启动多个程序在下一行添加对应的命令就可以，像这样：

![image](http://upload-images.jianshu.io/upload_images/13612520-05960c45af65d05c?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

编写多条启动命令

这样就能做到点一下启动多个程序了。

#### 一些简单好用的快捷键和命令

1.  win+d:显示桌面

2.  alt+tab 切换

3.  win+l 锁屏

4.  win+r：运行常用命令，这些命令比较好用的有cmd(控制台窗口)、control(控制面板)、mspaint(画图)、regedit(注册表)、explorer(资源管理器)、services.msc(查看服务，可以利用这个命令禁用服务列表里的windows更新程序，免得它老是提示更新)，mstsc(远程连接，需要进行相应的设置)