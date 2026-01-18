---
title: '在vscode中编写markdown '
date: 2019-04-12 11:50:38
tags: tool
---
作者：muggle

#### 为什么要markdown

&nbsp;&nbsp;markdown语法学习成本低，而且非常方便排版，如果你经常写文章，那么你就很有必要掌握markdown了，而且在vscode中编写markdown也非常方便，只需掌握几个快捷键，安装几个插件就能极大的提高你的写作效率。
<!-- more -->
#### 插件安装使用

##### 使用设置相关

ctr+shift+x 输入markdown preview enhanced下载安装，
安装好之后新建 .md文件就能愉快的写文章了，这里对markdown语法就不做介绍了，比较简单；
说一下插件怎么使用
ctrl+shift+v 打开预览，按F1或者ctr+shift+p输入Markdown Preview Enhanced: Customize Css 可改预览样式；对于一些常用的代码段还可以在vsocde中设置代码段快捷键，一键生成代码或文字。
<!--more-->

附上自己常用的预览样式

```js
.markdown-preview.markdown-preview {
  background-color: rgb(46, 45, 45);
  color: rgb(204,120,50);
  font-size: 16px;
  font-family: 'Franklin Gothic Medium', 'Arial Narrow', Arial, sans-serif;
  h1{
    font-size: 70px;
    color: bisque;
  }
  h2{
    font-size: 55px;
    color: bisque;
  }
  h3{
    font-size: 40px;
    color: bisque;
  }
  h4{
    font-size: 30px;
    color: bisque;
  }
  h5{
    font-size: 20px;
    color: bisque;
  }
  h6{
    font-size: 15px;
    color: bisque;
  }
  code{
    color: red;
    
  }
  pre{
    // color:oldlace;
    
  }
  
  blockquote{
    color: skyblue;
  }
  .slides{
    color: antiquewhite;
  }
}

```

##### 插件使用的一些语法

具体使用细节可查看[markdown preview enhanced](https://www.bookstack.cn/read/mpe/zh-cn-customize-css.md),这里只是对常用功能做介绍

###### toc

在你的文档里输入
> [TOC]

就能产生一个目录

###### 引入外部文件
语法为：
> @import "你的文件"

可引入 md 图片 html等，文件的路径为绝对路径或相对路径或者网络路径

###### 制作幻灯片
幻灯片语法为：
```js
---
presentation:
  width: 800
  height: 600
---
<!-- slide -->
在这里编写你的幻灯片。。。

```

##### 导出为PDF Word 等
pdf需要在 markdown 文件中的 front-matter 里声明 pdf_document 的输出类型：
```js
---
title: "test"
author: test
date: March 22, 2020
output: pdf_document
---
```
你可以通过 path 来定义文档的输出路径。例如：
```js
---
title: "Habits"
output:
  pdf_document:
    path: /Exports/Habits.pdf
---
```
word需要在 markdown 文件中的 front-matter 里声明 word_document 的输出类型：
```
---
title: "Habits"
author: John Doe
date: March 22, 2005
output: word_document
---
```
输出路径同pdf;

保持为markdown可以包含所有的绘制的图形（为 png 图片），code chunks，以及数学表达式（图片形式）等等
通过 front-matter 来设置图片的保存路径以及输出路径。

```
---
markdown:
  image_dir: /assets
  path: output.md
  ignore_from_front_matter: true
  absolute_image_path: false
---
```
image_dir 可选
定义了哪里将保存你的图片。例如，/assets 意味着所有的图片将会被保存到项目目录下的 assets 文件夹内。如果 image_dir。如果 image_dir 没有被定义，那么插件设置中的 Image save folder path 将会被使用。默认为 /assets。

path 可选
定义了哪里输出你的 markdown 文件。如果 path 没有被定义，filename_.md 将会被使用。

ignore_from_front_matter 可选
如果设置为 false，那么 markdown 将会被包含于导出的文件中的 front-matter 中。

absolute_image_path 可选
是否使用绝对（相对于项目文件夹）图片路径。


对于vscode 中编写markdown就介绍这么多，小伙伴有任何疑问都可以与我邮件或者微信qq交流

#### vscode的一些快捷键
Ctrl+n： new 一个文件
Ctrl+b: 关闭左侧菜单
ctr+左右方向键：光标跳跃到下一个单词
alt+上下方向键：上/下移一行
ctrl+d：选中一个单词
ctrl+x:删除一行
ctrl+1/2/3:分屏
ctrl+w：关闭当前窗口