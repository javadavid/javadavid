---
layout: post
title:  "Android activity 学习记录(1) - 基本传值"
date:   2015/11/13 10:38:30 
categories:
- 技术
tags:
- Android
---

今天正式开始学习android开发。以前只是片面的了解过各个组件和结构功能，现在开始系统的学习。

每一个android启动都会创建一个activity组件，程序通过mainifest文件启动主线程的activity;配置通过intent filter进行过滤；

    <category android:name="android.intent.category.LAUNCHER" />

每一个相应的activit都应该配置在声明其中

	<activity android:name=".B_Activty" android:label="这个是第二个页面"/>

#### **1、关于activity之间的传值**

- 直接通过intent对象，一般只传递一些比较简单的数据；intent对象存在于各个组件(component)之间，通过构造Intent(Context packageContext, Class<?> cls)实例化，使用startActivity(Intent)启动传递；

		//设置值
		//直接通过Intent传值
		i.putExtra("msg", "第一个页面向第二个传值");
		i.putExtra("mame", "dison");
		startActivity(i)
		
		//取得值
		Intent intent=getIntent();
		String msg=intent.getStringExtra("msg");
		String name=intent.getStringExtra("mame");
		
- 通过intent对象打包的bundle对象传递，可以传递对象或一些复杂结构的数据等。只在activity之间传递
		
		//通过Intent Bundle传值
		Bundle bundle=new Bundle();
		bundle.putString("sex", "男");
		bundle.putInt("age",20);
		//放入Intent对象中
		i.putExtras(bundle);
		startActivity(i);
			
		//取值
		MyApplication myapp=(MyApplication) getApplication();
		myapp.appInfo.get("sex")
		myapp.appInfo.get("age")
		
- 通过静态成员变量传递，此方式不推荐使用；
- 通过内置的application对象，需要在配置文件中声明application对象的名称；
		
		//设置值
		MyApplication myapp=(MyApplication) getApplication();
		myapp.appInfo.put("sex","男");
		myapp.appInfo.put("age", 10);
		
		//类
		public class MyApplication extends Application {
			//通过application设置全局的变量；当系统启动时候创建。所有的其中的 Activity 
			public Map<String, Object> appInfo=new HashMap<String, Object>();
		}
		
		//XML声明application对象 android:name
		<application
		    android:allowBackup="true"
		    android:icon="@drawable/ic_launcher"
		    android:label="@string/app_name"
		    android:theme="@style/AppTheme" 
		    android:name=".MyApplication">
		
		//取值
		firstView.setText(myapp.appInfo.get("sex")+"\n"+myapp.appInfo.get("age"));
关于application：android默认启动时候会产生一个app对象，既一个单例的对象进程，所有的数据在程序中是共享的，则可以在各个activity中访问和改变；

#### **2、取得activity的返回值**

- 通过startActivityForResult(Intent intent, int requestCode)提交到相应的activity，t相应的activity通过setResult(int resultCode, Intent data)。最后通过重载onActivityResult(int requestCode, int resultCode, Intent data)方法来实现回显返回的值
		
		//通过startActivityForResult 将intent和requestCode传递到B_Activty中
		Intent i=new Intent(getApplicationContext(),B_Activty.class);
		startActivityForResult(i, 10);
		
		//B_activity中通过setResult(int resultCode, Intent data)设置返回code和intent
		Intent data=new Intent();
		data.putExtra("retmsg", "这个是BActivity的返回值");
		setResult(RESULT_OK, data);
		finish();//结束activity

		//通过重载onActivityResult 判断返回code和是否调用成功 实现数据的回显
		protected void onActivityResult(int requestCode, int resultCode, Intent data){
			if(requestCode==10&&resultCode==RESULT_OK){
				tv.setText(data.getStringExtra("retmsg"));
			}
			super.onActivityResult(requestCode, resultCode, data);
		}


