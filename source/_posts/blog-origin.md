---
title: 博客搭建新司机指南
date: 2019-04-22 15:17:24
tags: tool
---

作者：muggle

## 准备工作

### 安装hexo并创建一个博客项目

在安装hexo之前请确保安装了git 和node.js

打开cmd，输入

```js
npm install -g hexo-cli
```

<!-- more -->

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

可以在 `_config.yml` 中修改大部分的配置。配置参数说明：

| 参数          | 描述                                                         |
| :------------ | :----------------------------------------------------------- |
| `title`       | 网站标题                                                     |
| `subtitle`    | 网站副标题                                                   |
| `description` | 网站描述                                                     |
| `author`      | 您的名字                                                     |
| `language`    | 网站使用的语言                                               |
| `timezone`    | 网站时区。Hexo 默认使用您电脑的时区。[时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)。比如说：`America/New_York`, `Japan`, 和 `UTC` 。 |

## 撸博客

### 新建文章并查看效果

在项目文件夹下打开cmd 执行

```java
hexo new "test"
```

test 为你的文件名，在source文件下的_posts 文件夹里有一个test.md；用markdown编辑器打开，就能写博客辣。

在这个md文件头部有一个`title`的属性，就是你的博客名，还可以在该头部配置日期等属性，这个文件最上方以 `---` 分隔的区域叫Front-matter。以下是一些预先定义的参数，您可在模板中使用这些参数值并加以利用。

| 参数         | 描述                 | 默认值       |
| :----------- | :------------------- | :----------- |
| `layout`     | 布局                 |              |
| `title`      | 标题                 |              |
| `date`       | 建立日期             | 文件建立日期 |
| `updated`    | 更新日期             | 文件更新日期 |
| `comments`   | 开启文章的评论功能   | true         |
| `tags`       | 标签（不适用于分页） |              |
| `categories` | 分类（不适用于分页） |              |
| `permalink`  | 覆盖文章网址         |              |

写完文章保存后，在原来打开的命令窗口 运行

```java
hexo g
```

这个指令是构建静态页面，它会在项目下生成一个public文件夹，里面就是我们`hexo g`得到博客静态页面，运行

```java
hexo s
```

将代码部署到本地，访问http://localhost:4000/可以查看你的博客效果

### 上传

博客上传之前需要在github上建立一个仓库，仓库名称要为`用户名.github.io`，因为我们博客就算基于gitpages来搭建的，所以我们要按照github的要求来命名。

创建成功之后，修改 hexo 的 `_config.yml` 文件，配置 GitHub 地址，如下：

```java
deploy:  
	type: git  
	repo: 仓库地址  
	branch: master
```

配置完成运行

```java
hexo d 
```

完成部署，这个时候可以访问 `用户名.github.io`这个网址来查看自己的博客

### hexo命令一览

```
$ hexo init [folder]
```

新建一个网站。如果没有设置 `folder` ，Hexo 默认在目前的文件夹建立网站。

**new**

```
$ hexo new [layout] <title>
```

新建一篇文章。如果没有设置 `layout` 的话，默认使用 [_config.yml](https://hexo.io/zh-cn/docs/configuration) 中的 `default_layout` 参数代替。如果标题包含空格的话，请使用引号括起来。

```
$ hexo new "post title with whitespace"
```

**generate**

```
$ hexo generate
```

生成静态文件。

| 选项             | 描述                   |
| :--------------- | :--------------------- |
| `-d`, `--deploy` | 文件生成后立即部署网站 |
| `-w`, `--watch`  | 监视文件变动           |

该命令可以简写为

```
$ hexo g
```

**publish**

```
$ hexo publish [layout] <filename>
```

发表草稿。

**server**

```
$ hexo server
```

启动服务器。默认情况下，访问网址为： `http://localhost:4000/`。

| 选项             | 描述                           |
| :--------------- | :----------------------------- |
| `-p`, `--port`   | 重设端口                       |
| `-s`, `--static` | 只使用静态文件                 |
| `-l`, `--log`    | 启动日记记录，使用覆盖记录格式 |

**deploy**

```
$ hexo deploy
```

部署网站。

| 参数               | 描述                     |
| :----------------- | :----------------------- |
| `-g`, `--generate` | 部署之前预先生成静态文件 |

该命令可以简写为：

```
$ hexo d
```

**render**

```
$ hexo render <file1> [file2] ...
```

渲染文件。

| 参数             | 描述         |
| :--------------- | :----------- |
| `-o`, `--output` | 设置输出路径 |

**migrate**

```
$ hexo migrate <type>
```

从其他博客系统 [迁移内容](https://hexo.io/zh-cn/docs/migration)。

**clean**

```
$ hexo clean
```

清除缓存文件 (`db.json`) 和已生成的静态文件 (`public`)。

在某些情况（尤其是更换主题后），如果发现您对站点的更改无论如何也不生效，您可能需要运行该命令。

**list**

```
$ hexo list <type>
```

列出网站资料。

**version**

```
$ hexo version
```

显示 Hexo 版本。

**选项**

**安全模式**

```
$ hexo --safe
```

在安全模式下，不会载入插件和脚本。当您在安装新插件遭遇问题时，可以尝试以安全模式重新执行。

**调试模式**

```
$ hexo --debug
```

在终端中显示调试信息并记录到 `debug.log`。当您碰到问题时，可以尝试用调试模式重新执行一次，并 [提交调试信息到 GitHub](https://github.com/hexojs/hexo/issues/new)。

**简洁模式**

```
$ hexo --silent
```

隐藏终端信息。

**自定义配置文件的路径**

```
$ hexo --config custom.yml
```

自定义配置文件的路径，执行后将不再使用 `_config.yml`。

**显示草稿**

```
$ hexo --draft
```

显示 `source/_drafts` 文件夹中的草稿文章。

**自定义 CWD**

```
$ hexo --cwd /path/to/cwd
```

自定义当前工作目录（Current working directory）的路径。

## 进阶

### 换主题

下载主题到`./themes`目录下，修改 hexo 的 _config.yml 文件的theme属性为你的主题名就ok了，下面推荐几个hexo主题

- [hexo-theme-next](<https://github.com/iissnan/hexo-theme-next>)
- [hexo-theme-yilia](https://link.zhihu.com/?target=https%3A//github.com/litten/hexo-theme-yilia)
- [uno](https://link.zhihu.com/?target=https%3A//github.com/daleanthony/uno)
- [hexo-theme-strict](https://link.zhihu.com/?target=https%3A//github.com/17/hexo-theme-strict)

### 换域名

首先申请一个域名，然后在博客所在目录下的 source 目录中，创建一个 CNAME 文件，文件内容就是你的域名，然后执行 `hexo d` 命令将这个文件上传到 GitHub就可以了；域名换好后需要配置域名解析。

## 附

### markdown 语法一览

```java
# 这是一级标题
## 这是二级标题
### 这是三级标题
#### 这是四级标题
##### 这是五级标题
###### 这是六级标题
**这是加粗的文字**
*这是倾斜的文字*
***这是斜体加粗的文字***
~~ 这是加删除线的文字~~
> 这是引用的内容
三个或者三个以上的 - 或者 *为分割线
![图片alt](图片地址 ''图片title'')
[超链接名](超链接地址 "超链接title")
    
- 列表内容
+ 列表内容
* 列表内容
注意：- + * 跟内容之间都要有一个空格

1.列表内容
2.列表内容
3.列表内容

注意：序号跟内容之间要有空格

表头|表头|表头
---|:--:|---:
内容|内容|内容
内容|内容|内容
`代码内容`
​```
代码内容
​```
```



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

