---
layout: post
title:  "Android activity 学习记录(2) - 生命周期"
date:   2015/11/13 13:38:01 
categories:
- 技术
tags:
- Android
---

### Activity正常执行的生命周期

	onCreate(): 初始化Activity	
	onStart():	显示Activity 显示界面	 	前台界面	
	onResume()： 用户交互（比如点击，获得焦点）  活动进程状态
	onPause(): 停止与用户交互
	onStop(): 关闭Activity	后台进程状态	
	onRestart():再次打开Activity
	onDestroy():销毁Activity

----------

#### 1、启动activity状态	

	onCreate -- onStart -- onResume
	
![android_activity1]({{site.baseurl}}/public/img/android_activity1.png)

#### 2、当点击Home按键时候；<b style='color:red'>HOME也是一个Activity(Main Activity)</b>
	
	onPause -- HOME:( onCrate -- onStart -- onResume ) -- onStop

![android_activity2]({{site.baseurl}}/public/img/android_activity2.png)

#### 3、当点击任务调度器 调出任务时 ( 从HOME到原始Activity界面 )
	
	HOME:onPause -- A:(onRestart -- onStart -- onResume) -- HOME:onStop -- onDestroy 

![android_activity3]({{site.baseurl}}/public/img/android_activity3.png)

----------

#### 4、Activity跳转 MainActivity --> BActivty 如下图所示 （A页面被B页面完全覆盖）；
	
![android_activity4]({{site.baseurl}}/public/img/android_activity4.png)


#### 5、当B页面返回按键时候 activity执行过程；
![android_activity5]({{site.baseurl}}/public/img/android_activity5.png)

----------

#### 以上情况BActivity是对话框按钮时候的启动、跳转、返回
![android_activity6]({{site.baseurl}}/public/img/android_activity6.png)

跳转
![android_activity7]({{site.baseurl}}/public/img/android_activity7.png)

返回
![android_activity8]({{site.baseurl}}/public/img/android_activity8.png)


	- 当A跳转到B时候，A如果被B覆盖：则A会执行onStop方法；否则不会执行
	- onPause方法是在Activity在中断过程中的执行的方法；


#### 界面旋转变量的保存

>#### Activity会重新创建和加载，使数据的值重置，可以使用以下覆写的2个方法进行保存取得数据；
	
	//在onPause方法后执行，保存变量值
	protected void onSaveInstanceState(Bundle outState)

	//这个在onStart方法后执行，可以取得变量值
	protected void onRestoreInstanceState(Bundle savedInstanceState)
	
	protected void onCreate(Bundle savedInstanceState)
	
	
通过方法：

savedInstanceState.putInt(key, value)各种保存数据的方法，保存相关数据，然后在Activity周期的onCreate和onRestoreInstanceState中可以通过savedInstanceState.get(key)取得变量值；