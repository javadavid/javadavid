---
layout: post
title:  "Android Intent 学习记录 - 7大属性"
date:   2015/11/16 10:40:00 
categories:
- 技术
tags:
- Android
---

### **intent的作用**

1. 包装android组件；
2. 启动activity、service、发送广播；
3. 组件之间相互传值；


### **七大属性有**

>*action，data ，category ，type， component， extras， flags*


### **“ 显示 ”启动一个组件的写法（只能在同一个task中）：**

首先来看componentName的构造方法
	
	ComponentName(Context pkg, Class<?> cls) 
	ComponentName(Context pkg, String cls) 
	ComponentName(Parcel in) 
	ComponentName(String pkg, String cls)  


- 使用ComponentName来创建一个组件（这里可以是Activity，Service，BroadcastReceiver或者ContentProvider。），然后使用intent声明跳转；
	
		Intent intent=new Intent(); 
		//创建一个组件
		ComponentName cm=new ComponentName(getApplicationContext(),BActivity.class)
		
		//声明并调转	
		intent.setComponent(cm);
		startActivity(intent);

- 使用intent的另外一种声明跳转；
	
		intent.setClass(getApplicationContext(), BActivity.class);
	
	
### **“ 隐式 ”启动一个组件的方法（可用在不同一个task中）：**

- 需要通过action来指定启动的activity，要在manifest中声明intent-filter action名称 和category；

		//直接构造
		Intent intent=new Intent("com.demo.activity05_task.BActivity"); 

		//第二种是通过方法
		intent.setAction("com.demo.activity05_task.BActivity")


相关的例子可参考 [Intent01](https://github.com/XH888/AndroidDemo)


### **关于intent的数据配置**

1. data：指定传送值的属性值； 比如打电话(tel:10086)、播放音乐必须要提供的数据格式；
2. type：mimetype:提供的文件类型 如：文本文件（text/*）
3. extra：存放扩展数据类型，intent.putExtra(name, value)
4. flag：影响启动组件的特性（运行模式），一般在广播的时候启动activity设置flag属性；intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

可以参见一下的代码：

	public void onCall(View v) {
		Intent intent=new Intent(Intent.ACTION_CALL );
		intent.setData(Uri.parse("tel:10086"));
		startActivity(intent);
	}

	public void onWeb(View v) {
		Intent intent=new Intent(Intent.ACTION_VIEW);
		intent.setData(Uri.parse("http://www.baidu.com"));
		startActivity(intent);
	}

	public void onShare(View v) {
		Intent intent=new Intent(Intent.ACTION_SEND);
		intent.setType("text/*");
		intent.putExtra(Intent.EXTRA_TEXT,"要发送的信息。。。");
		startActivity(intent);
	}
	public void onSMS(View v) {
		Intent intent=new Intent(Intent.ACTION_SENDTO);
		intent.setData(Uri.parse("smsto:10086"));
		intent.putExtra( "sms_body","要发送短信的内容。。");	//短信内容的常量是 ‘sms_body’
		startActivity(intent);
	}

