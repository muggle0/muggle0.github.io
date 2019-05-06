---
title: git subtree多项目合并试验
date: 2019-05-05 16:48:52
tags: javaee
---

## 说明

git subtree可将多个git项目合并在一起，可解决protobuf更新的问题；

打包maven私有仓库也可行，但是maven私有仓库不适合频繁更新，而protobuf更新会很频繁。

## 测试

git clone一个新项目

git remote add <name> <url> 添加一个远程子仓库

git subtree add --prefix=<dir> <name> master

git push 会把子仓库的文件提交，合情合理

更新子仓库的方法

git subtree push --prefix=<dir> <name> master



命令一览

```linux
git subtree add   --prefix=<prefix> <commit>
git subtree add   --prefix=<prefix> <repository> <ref>
git subtree pull  --prefix=<prefix> <repository> <ref>
git subtree push  --prefix=<prefix> <repository> <ref>
git subtree merge --prefix=<prefix> <commit>
git subtree split --prefix=<prefix> [OPTIONS] [<commit>]
```

由于不能使用idea 来操作子仓库，需要掌握手动解决冲突的方法

 git 知识复习

git checkout -b xxx

git branch xxx

git merge xxx

## over

自此，protobuf的文件同步找到了一个较好的解决方法

