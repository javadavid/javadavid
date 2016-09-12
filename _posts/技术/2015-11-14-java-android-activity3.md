---
layout: post
title:  "Android activity 学习记录(3) - 任务和退回栈"
date:   2015/11/14 15:07:34 
categories:
- 技术
tags:
- Android
---
任务(task)和退回栈：

## 解释	
任务：用来保存activity组件实例(既android应用程序容器)，将activity事例保存在内存中，这个内存结构是退回栈，启动时候就产生一个MainActivity放入其中。有先进后出的原则；

### 获取task信息
android.app.ActivityManager：系统服务组件管理器

	//取得系统的Activity_Task信息
	public static void printTask(Context context ){
		//系统服务组件 
		ActivityManager am=(ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
		//取得正在运行的任务；
		List<RunningTaskInfo> runningTasks = am.getRunningTasks(10);
		for(RunningTaskInfo rtask:runningTasks){
			Log.i("info", "id:"+rtask.id+
					",num:"+rtask.numActivities+	//堆栈中的组件个数
					",base:"+rtask.baseActivity.getClassName()+	//栈底组件
					",top:"+rtask.topActivity.getClassName());	//栈顶组件
												
		}
	}
	
AndroidManifest.xml:配置需要配置权限

	<uses-permission android:name="android.permission.GET_TASKS"/>

任务中Activity跳转几次后显示结构 ( standard模式：可以创建多个相同的activity,也可以在不同task中 )

![android_activity9.PNG]({{site.baseurl}}/public/img/android_activity9.png)

结果可以看出：
	
- activity会产生叠加的效果，产生一个堆栈空间
- 点击返回到前一个activity，消亡当前activity

### 隐式调用Activity

隐式调用不同任务的Activity（前台与后台 的关系）

AndroidManifest.xml配置

	<!-- 需要其他任务隐式访问启动的时候，定义 intent-filter 节点 和 名称 ，action代表组件的唯一标识-->
    <activity android:name="com.demo.activity05_task.BActivity">
        <intent-filter >
            <action android:name="com.demo.activity05_task.BActivity"/>
            <category android:name="android.intent.category.DEFAULT"/>
        </intent-filter>
    </activity>
    
    <activity android:name="com.demo.activity05_task.CActivity">
        <intent-filter >
            <action android:name="com.demo.activity05_task.CActivity"/>
            <category android:name="android.intent.category.DEFAULT"/>
        </intent-filter>
    </activity>

java class 需要通过隐式声明Intent的方法启动任务
	
	Intent intent=new Intent("com.demo.activity05_task.BActivity");	//action名称；
	startActivity(intent);



### **运行模式：**AndroidManifest.xml中 android:launchMode
	
#### standard

>#### 标准模式，默认，通常的堆栈模式；


#### singleTop

>#### 启动相应的任务activity如果不存在栈顶，则创建一个新的activity放到自己的栈顶，存在则不用创建，然后将这个Activity复制放到本地栈中；
>
>#### 个人理解成：始终都是合理利用资源拿来用的类型，总是在栈顶寻找对象，比较死板；



#### singleTask

>#### 启动相应的任务的activity	
>
>#### 若存在，将启动任务中的activity对象的堆栈上面的activity进行抛出，不将启动activity放到本地中
>
>#### 若不存在，则在则创建一个在启动activity上面；

>#### 个人理解成：每次启动activity对象也是会去找有没有对象，不同的是在调用task中全断搜索，然后抛出没用的在上面的activity，比较灵活；


#### singleInstance

>#### 单独创建一个任务放入activity: 此activity启动后的任务会放到原来的任务中，既只能存放此单例的任务只能放一个启动activity，销毁后会回到原始调用的task

>#### 个人理解成：总是把调用的activity放到个临时的task中，调用完后恢复到原始返回流程，比较任性；

关于四种模式的简图我直接放上了。 可能理解还有些错误或者不深刻，慢慢消化

![android_activity10]({{site.baseurl}}/public/img/android_activity10.png)

另外可以参考这篇 [帖子](http://blog.csdn.net/moreevan/article/details/6788048 "CSDN")；讲解的很详细了


#### singleTask和singleInstance

**另外：**对于singleTask和singleInstance中，存在已经创建Activity的情况，若其中已经传递过Intent对象，则本地task创建的intent值无法传递。需要覆盖onNewIntent(Intent intent)方法才可以传递新的对象；

	@Override
	protected void onNewIntent(Intent intent) {
		setIntent(intent);
		super.onNewIntent(intent);
	}