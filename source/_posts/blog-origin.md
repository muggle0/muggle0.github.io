---
title: 博客搭建新司机指南
date: 2019-04-22 15:17:24
tags: tool
---

## 准备工作

### 安装hexo并创建一个博客项目

在安装hexo之前请确保安装了git 和node.js

打开cmd，输入

```js
npm install -g hexo-cli
```

<!--more-->

创建一个名为blog的博客项目

```
$ hexo init blog
$ cd blog
$ npm install
```

新建完成后，指定文件夹的目录如下：

```xml
.
├── _config.yml
├── package.json
├── scaffolds
├── source
|   ├── _drafts
|   └── _posts
└── themes
```

### 配置

## 撸博客

### 新建文章并查看效果

### 上传

### hexo命令一览

## 进阶

### 换主题

### 换域名

## 附

### markdown 语法一览

### markdown文档编辑器Typora

百度Typora 下载安装好之后点 文件>偏好设置>勾选自动保存，这样就不怕忘记保存而文档丢失了；

快捷键：
- 标题：ctrl+数字
- 表格：ctrl+t
- 生成目录：[TOC]按回车
- 选中一整行：ctrl+l
- 选中单词：ctrl+d
- 选中相同格式的文字：ctrl+e
- 跳转到文章开头：ctrl+home
- 跳转到文章结尾：ctrl+end
- 搜索：ctrl+f
- 替换：ctrl+h
- 引用：输入>之后输入空格
- 代码块：ctrl+alt+f
- 加粗：ctrl+b
- 倾斜：ctrl+i
- 下划线：ctrl+u
- 删除线：alt+shift+5
- 插入图片：直接拖动到指定位置即可或者ctrl+shift+i
- 插入链接：ctrl + k

左下角有一个 O 和 </>的符号 O表示打开侧边栏 </>查看文档源代码；

可去官网下载好主题之后点 文件>偏好设置>打开主题文件夹将解压好的主题相关文件复制粘贴到该目录下（一般是一个  主题名称文件夹 和一个 主题名称.css文件）之后重启编辑器 然后点 主题可看见安装好的主题。

