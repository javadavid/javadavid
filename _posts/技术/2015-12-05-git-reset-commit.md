---
layout: post
title:  "Git 使用回退上次Commit内容"
date: 2015/12/5 15:49:50 
categories:
- 技术
tags:
- Git
---


先看看Git版本库的关系图：

![201211042015584140.gif]({{site.baseurl}}/public/img/201211042015584140.gif)



现在在使用Git的时候Window桌面版本好像没有提供硬回退的操作（貌似我没有找到），果然还是要会dos版本的啊，这样也利于学习和理解；

可以使用git reset操作来回退此操作：

	git reset --hard <commit_id>

    git push origin HEAD --force


根据–soft –mixed –hard，会对working tree和index和HEAD进行重置:

- git reset –mixed：此为默认方式，不带任何参数的git reset，即时这种方式，它回退到某个版本，只保留源码，回退commit和index信息
- git reset –soft：回退到某个版本，只回退了commit的信息，不会恢复到index file一级。如果还要提交，直接commit即可
- git reset –hard：彻底回退到某个版本，本地的源码也会变为上一个版本的内容

摘自
[http://www.douban.com/note/189603387/](http://www.douban.com/note/189603387/)


