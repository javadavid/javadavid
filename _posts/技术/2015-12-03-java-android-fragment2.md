---
layout: post
title:  "Android Fragment 学习记录(2) - 生命周期"
date: 2015/12/3 9:18:33 
categories:
- 技术
tags:
- Android
---

### Fragment的生命周期

Activity创建：

- onCreate()：寻找是否存在fragment控件，若不存在则返回null，存在则返回

存在fragment，则创建：在Fragment内部执行以下四个方法

- onAttach()：fragment加入到activity中
- onCreate()：创建fragment框架
- onCreateView()：创建视图，activity可以取得fragment的视图
- onActivityCreated()：activity视图onCreate创建完成后，调用此方法

后来与Activity主视图相关联，也就是随着Activity的生命周期

- 可见状态（前台运行）
	- onStart()：开始运行
	- onResume()：中断
- 停止状态（后台运行，中间可能执行跳转或者的返回）
	- onPause()：暂停
	- onStop()：结束


最后当Activity执行销毁onDestroy()时候，Fragment调用

- onDestroyView()：fragment从视图中移除的时候调用方法
- onDestroy()：activity完成销毁的回调的函数
- onDetach()：fragment和activity分离的时候调用的函数

**开始声明周期到结束销毁**

- 创建显示是从Activity，然后创建Fragment
- 运行中Fragment将自身状态交给Activity，随之运行
- 销毁时候是先销毁Fragment自身，然后在回调给Activity的onDestroy()

Activity和Fragment生命周期对比

![Fragment和activity生命周期对比](http://img.my.csdn.net/uploads/201301/22/1358841101_4818.png)

下面来看下简单的Fragment的系统执行顺序


启动和运行状态：（代码详见Fragment04）

![android_fragment04.png]({{site.baseurl}}/public/img/android_fragment04.png)


停止和销毁的运行状态：

![android_fragment05.png]({{site.baseurl}}/public/img/android_fragment05.png)


