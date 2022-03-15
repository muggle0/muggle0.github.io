---
title: git
date: 2019-05-24 14:24:56
tags: tool
---

#### 初始化并提交到远程

git init <br>
git config --global user.name"ssss"
git add README.md <br>
git commit -m "first commit" <br>
git remote add origin https://github.com/Xanthuim/nodejs_express_sample.git <br>
git push -u origin master <br>（$ git push -u origin master 上面命令将本地的master分支推送到origin主机，同时指定origin为默认主机，后面就可以不加任何参数使用git push了）

<!--more-->

git branch --set-upstream-to master origin/master或者git fetch关联远程分支，然后git pull origin master --allow-unrelated-histories强制合并

#### 远程仓库初始化并关联本地

git clone url<br>
git config --global user.name"ss"<br>
git push<br>

#### HEAD的含义

代表当前仓库版本号<br>
HEAD^ 和HEAD~<br>
HEAD^+数字表示当前提交的父提交。具体是第几个父提交共同过^+数字指定，EAD^1第一个父提交，该语法只能用于合并(merge)的提交记录，因为一个通过合并产生的commit对象才有多个父提交。
HEAD~(等同于HEAD^,注意没有加数字)表当前提交的上一个提交。<br>
如果想获取一个提交的第几个父提交使用HEAD^+数字,想获取一个提交的上几个提交使用HEAD~。HEAD^和HEAD~或HEAD^^和HEAD~~并没有区别，只有HEAD^+数字才和HEAD~有区别。

#### $ git reset 撤销方式

git reset --soft 版本号<br>
只撤销本地仓库数据到版本号 <br>
git reset --mixed 版本号<br>
撤销本地和暂存区仓库到版本号<br>
git reset --hard 版本号<br>
撤销 工作区 暂存区 本地仓库到版本号<br>
git reset --hard origin/master<br>
####

HEAD的含义：代表当前仓库最新版本。HEAD^ 和HEAD~的意义和区别HEAD^+数字表示当前提交的父提交。具体是第几个父提交共同过^+数字指定，EAD^1第一个父提交，该语法只能用于合并(merge)的提交记录，因为一个通过合并产生的commit对象才有多个父提交。HEAD~(等同于HEAD^,注意没有加数字)表当前提交的上一个提交。<br>如果想获取一个提交的第几个父提交使用HEAD^+数字,想获取一个提交的上几个提交使用HEAD~。HEAD^和HEAD~或HEAD^^和HEAD~~并没有区别，只有HEAD^+数字才和HEAD~有区别。 git reset 撤销方式git reset --soft 版本号只撤销本地仓库数据到版本号git reset --mixed 版本号该方式为默认方式（即git reset 版本号）撤销本地和暂存区仓库到版本号git reset --hard 版本号撤销 工作区 暂存区 本地仓库到版本号git reset --hard origin/master远程仓库代码覆盖工作区 暂存区 本地仓库以上指令都不会对未归入git控制的文件进行管理也就是从未add过的文件git是不会去删除撤销它的撤销单个文件的修改git reset HEAD xxx.txt本地覆盖暂存区的代码git checkout xxx.txtgit checkout .将暂存区的代码覆盖工作区 “.”是通配所有文件

git 强制pull 

git pull origin master --allow-unrelated-histories 

git 强制push git push -f 

合并

git merge origin master 

git status

git 保存工作区修改 不提交

git stash save "xxx" （入栈，工作区代码放入到stash中）

git stash pop (出栈，从stash中拿保存的代码)

## 指令一览

- 强推
对受保护分支无法使用强推，强推解决多仓库不同源问题
git push 远程仓库名 本地分支:远程仓库名 --force

- commit 错误回滚

git revert是用一次新的commit来回滚之前的commit，git reset是直接删除指定的commit 。
git reset --hard --mixed(default) --soft 分别覆盖3个、2个、1个位置的代码，--mixed（默认的参数）只会保留working copy里的代码

git cherry-pick <commit_id> 选择合并

git subtree 子仓库 特殊场合使用

git merge dev 合并

git remote rm origin 删除远程仓库

git push origin --delete dev 删除远程分支

- 对于提交错误但未push的commit 可以使用idea 的undo commit 进行回滚

- 多仓库远程推送 git push origin local:remote

git branch -vv 查看本地分支关联的远程分支

git checkout -b dev origin/dev   切换远程分支