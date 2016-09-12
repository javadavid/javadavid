---
layout: post
title:  "Android Notification 学习记录"
date: 2015/11/27 11:18:12 
categories:
- 技术
tags:
- Android
---


## 作用

在下拉状态栏显示一个消息通知框；

**实例化**

- 通过构造Notification(int icon, CharSequence tickerText, long 
when) ：过时的方法
	- icon：设置启动的图标
	- 设置滚动栏的文字
	- 设置多长时间后显示

- 通过系统服务启动一个NotificationCompat.Builder产生Notification的参数，通过builder.build()来创建一个Notification


**启动：**

- 都是通过方法(NotificationManager) getSystemService(NOTIFICATION_SERVICE)实例化NotificationManager系统服务的组件
- notify(int id, Notification notification)方法启动相应的Notification，并且将其设置一个ID标识



实例化NotificationManager服务

	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		//由系统组件自动启动，直接通过getSystemService获取服务
		notifyManager=(NotificationManager) getSystemService(NOTIFICATION_SERVICE);
	}


### 发送普通通知

	public void notify01(View view){
		NotificationCompat.Builder builder=new NotificationCompat.Builder(getApplicationContext());
		builder.setSmallIcon(R.drawable.ic_launcher)	//设置小图标
				.setContentTitle("Notification 提示信息")
				.setContentText("通知的内容")
				.setTicker("标题栏滚动信息")
				.setAutoCancel(true)	//只有点击以后才消失（一直保存在通知栏：如腾许管家的状态下拉栏）
				.setOngoing(true)		//是否一直停留在状态栏	若是false:点击Clear则清除
				.setPriority(NotificationCompat.PRIORITY_HIGH)	//设置相关的优先级
				.setDefaults(Notification.DEFAULT_SOUND|Notification.DEFAULT_VIBRATE)	//默认的提示信息
				.setContentIntent(PendingIntent.getActivity(getApplicationContext(), 100, new Intent(Intent.ACTION_CALL,Uri.parse("tel:10086")),PendingIntent.FLAG_ONE_SHOT));
		notifyManager.notify(1, builder.build());		//第一个参数是本地程序中的notification的标识
	}
	
![android_notification01.png]({{site.baseurl}}/public/img/android_notification01.png)

### 发送进度条通知	
	
	public void notify02(View view){
		new Thread(){
			public void run() {
				NotificationCompat.Builder builder=new NotificationCompat.Builder(getApplicationContext());
				builder.setSmallIcon(R.drawable.ic_launcher)	//设置小图标
						.setContentTitle("Notification 提示信息")
						.setContentText("正在下载...")
						.setProgress(100, 0, false)
						.setTicker("正在下载...")
						.setOngoing(true)
						//.setDefaults(Notification.DEFAULT_SOUND|Notification.DEFAULT_VIBRATE)	//默认的提示信息
						.setContentIntent(PendingIntent.getActivity(getApplicationContext(), 100, new Intent(Intent.ACTION_CALL,Uri.parse("tel:10086")),PendingIntent.FLAG_ONE_SHOT));
				
				for(int i=0;i<=100;i+=5){
					builder.setProgress(100, i, false);	//设置成不确定性进度条
					try {
						Thread.sleep(1000);
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
					notifyManager.notify(2, builder.build());
				}
				builder.setTicker("下载完成").setContentText("下载完成");
				
				notifyManager.notify(2, builder.build());
			};
		}.start();
	}

![android_notification02.png]({{site.baseurl}}/public/img/android_notification02.png)


### 加载大`视图`信息

	public void notify03(View view){
		NotificationCompat.Builder builder=new NotificationCompat.Builder(getApplicationContext());
		builder.setSmallIcon(R.drawable.ic_launcher)	//设置小图标
				.setLargeIcon(BitmapFactory.decodeResource(getResources(), R.drawable.ic_launcher))
				.setContentTitle("Notification 提示信息")
				.setContentText("加载大视图信息");
		
		NotificationCompat.InboxStyle style=new NotificationCompat.InboxStyle(builder);
		style.addLine("第一条信息..").addLine("第二条信息..").addLine("第三条信息..");
		style.setSummaryText("总数99+");
		
		builder.setStyle(style);
		
		notifyManager.notify(3, builder.build());
	}


![android_notification03.png]({{site.baseurl}}/public/img/android_notification03.png)

### 加载大`图片`信息

	public void notify04(View view){
		NotificationCompat.Builder builder=new NotificationCompat.Builder(getApplicationContext());
		builder.setSmallIcon(R.drawable.ic_launcher)	//设置小图标
				.setLargeIcon(BitmapFactory.decodeResource(getResources(), R.drawable.ic_launcher))
			   	.setContentTitle("Notification 提示信息");
		
		NotificationCompat.BigPictureStyle style=new NotificationCompat.BigPictureStyle(builder);
		style.bigPicture(BitmapFactory.decodeResource(getResources(),R.drawable.logo))
			.setSummaryText("加载大图片信息");
		
		builder.setStyle(style);
		
		notifyManager.notify(3, builder.build());
	}

![android_notification04.png]({{site.baseurl}}/public/img/android_notification04.png)

## 说明
- setOngoing(boolean ongoing):是否一直停留在状态栏,若是false:点击Clear则清除
- setAutoCancel(boolean autoCancel)：消息栏点击后消失
- setDefaults(int defaults)：设置默认的提示信息。如：
```
(Notification.DEFAULT_SOUND|Notification.DEFAULT_VIBRATE)
```响铃和震动
- setContentIntent(PendingIntent intent)：设置默认点击的intent跳转
	- PendingIntent是Intend的一个包装，即将执行的Intent，通过静态方法getActivity(Context context, int requestCode, Intent intent, int flags)实现调用
- setProgress(int max, int progress, boolean indeterminate)：显示滚动条的进度，indeterminate参数表示是否是不确定性进度条

在加载大图片和大视图信息中

- NotificationCompat是android.support.v4.app下面的一个类，通过子类InboxStyle/BigPictureStyle分别实现加载大数据和大图片的信息
	- bigPicture(Bitmap b)：加载大图片
	- addLine(CharSequence cs)：加载多条文本信息
	- setSummaryText(CharSequence cs)：他们都是通过此方法设置备注信息
-最后通过builder.setStyle(style)设置和builder绑定。
















