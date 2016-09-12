---
layout: post
title:  "Android BroadcastReceiver 学习"
date: 2016/1/25 17:56:46 
categories:
- 技术
tags:
- Android
---

### BroadcastReceiver：
广播接收者：用来接收系统和应用的广播；比如系统的监听电量状态操作、网络状态等

### 动态注册接收系统广播操作：

MainActivity.java：

- 继承BroadcastReceiver实现 onReceive(Context context, Intent intent)：用来接收广播，其中包含了receiver对象的context和intent信息，一般系统消息都被装载到了Intent Extra中
- 实例化广播myBroadCastReceiver，和IntentFilter，其中IntentFilter接收Intent的实例操作类；
- 当启动registerReceiver(BroadcastReceiver receiver, IntentFilter filter)：将BroadCastReceiver中匹配的Action注册到Activity中
- 当销毁时候 unregisterReceiver 方法
- BatteryManager电池管理包含了一些对ACTION_BATTERY_CHANGED intent的一些电池的常量；
- 动态注册的地址由用户决定接收器的生命周期，activity onCreate - register和onDestroy - unregister

<nobr/>

	public class MainActivity extends Activity {
		private TextView msgTv;
		BroadcastReceiver myBroadCastReceiver;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			msgTv=(TextView) findViewById(R.id.msgId);
			//实例化广播
			myBroadCastReceiver = new MyBroadCastReceiver();
			
			//实例化广播过滤器
			IntentFilter filter = new IntentFilter();
		
			//添加系统的广播  电量改变  充电状态
			filter.addAction(Intent.ACTION_BATTERY_CHANGED);	
			filter.addAction(Intent.ACTION_POWER_DISCONNECTED);
			
			//注册广播
			registerReceiver(myBroadCastReceiver, filter);
		}
	
		@Override
		protected void onDestroy() {
			super.onDestroy();
			unregisterReceiver(myBroadCastReceiver);
		}

		class MyBroadCastReceiver extends BroadcastReceiver{
			@Override
			public void onReceive(Context context, Intent intent) {
				//接收到广播的处理方法，可以接收多个广播
				if(intent.getAction()==Intent.ACTION_BATTERY_CHANGED){
					int level=intent.getIntExtra(BatteryManager.EXTRA_LEVEL, 0);
					msgTv.setText("电量状态改变:"+level+"%");
				}else if(intent.getAction()==Intent.ACTION_POWER_DISCONNECTED){
					msgTv.setText("电源已经断开（是否是充电状态）");
				}
			}
		}
	}

![android_broadcastreceiver01.png]({{site.baseurl}}/public/img/android_broadcastreceiver01.png)

### 静态注册自定义广播地址

在AndroidManifest.xml：添加对receiver的声明和IntentFilter名称定义，接收器会随着系统的生命周期创建和销毁，不需要register和unregister

	<receiver android:name="com.example.receiver.MyReceiver">
		<intent-filter>
		    <action android:name="com.example.receiver.MY_RECEIVER"/>
		    <category android:name="android.intent.category.DEFAULT"/>
		</intent-filter>            
    </receiver>

通过Activity下面的sendBroadcast(intent)：发送intent广播信息；

	public class MainActivity extends Activity {
		BroadcastReceiver br;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			
			br=new MyReceiver();
			Intent intent = new Intent("com.example.receiver.MY_RECEIVER");  
		    intent.putExtra("msg", "hello receiver.");  
			sendBroadcast(intent);
		}
	}

MyReceiver.java：

	public class MyReceiver extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {
			Log.i("info", intent.getExtras().getString("msg"));
		}
	}

![android_broadcastreceiver02.png]({{site.baseurl}}/public/img/android_broadcastreceiver02.png)

### 静态注册查看网络状态信息；
NetWorkReceiver.java

- ConnectivityManager：管理网络状态，负责告诉程序改变的网络状态；
- NetworkInfo：包含网络状态的信息，getType():取得网络状态的标识;info.isAvailable()判断当前网络状态是否可用

<nobr/>

	//接收网络的方法类
	public class NetWorkReceiver extends BroadcastReceiver {
	
		@Override
		public void onReceive(Context context, Intent intent) {
			Log.i("info", intent.getAction());
			
			//取得系统服务连接管理
			ConnectivityManager conManger=(ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
			//网络信息管理
			NetworkInfo info = conManger.getActiveNetworkInfo();
			if(info!=null&&info.isAvailable()){
				if(info.getType() == ConnectivityManager.TYPE_MOBILE){
					Log.i("info", "网络连接：移动");
				}else if(info.getType() == ConnectivityManager.TYPE_WIFI){
					Log.i("info", "网络连接：Wifi");
				}
			}else{
				Log.i("info", "网络断开");
			}
		}
	}

AndroidManifest.xml：

	<!-- 静态注册广播接收器 -->
	<receiver android:name="com.example.receiver.NetWorkReceiver" >
		<intent-filter>
			<action android:name="android.net.conn.CONNECTIVITY_CHANGE"/>
		</intent-filter>
	</receiver>
   
![android_broadcastreceiver03.png]({{site.baseurl}}/public/img/android_broadcastreceiver03.png)

注意：在网络连接时，android.net.conn.CONNECTIVITY_CHANGE会有多个状态的改变（正在连接，连接成功）

### 不同应用间发送和接收自定义广播；
- 线程通过Context.sendBroadcast(Intent)发送；BroadCastReceiver04

布局文件activity_main.xml

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    android:layout_margin="10dp"
	    tools:context=".MainActivity" >
	    <Button
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:onClick="sendBroadCast"
	        android:text="sendBroadCast" />
	
	    <TextView
	        android:id="@+id/countId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content" />
	</LinearLayout>

MainActivity.java：

- 动态注册地址registerReceiver和取消注册地址unregisterReceiver
- 定义发送的地址的Action和权限Permission
- 启动线程sendBroadcast(Intent)/sendBroadcast(Intent,Permission)：发送到地址，无权限和有权限的

MainActivity.java

	public class MainActivity extends Activity {
		TextView countId;
		MyBroadCastReceiver receiver;
		
		private static final String EXTRA_TEXT="text";
		//广播的频道
		private static final String ACTION_TIMER="com.example.broadreciver04.timer";
		//权限
		private static final String ACTION_PERMISSION="com.example.broadreciver04.timer.PERMISSION";
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        countId=(TextView) findViewById(R.id.countId);
	        receiver=new MyBroadCastReceiver();
	        registerReceiver(receiver, new IntentFilter(ACTION_TIMER));
	    }
	    
	    @Override
	    protected void onDestroy() {
	    	unregisterReceiver(receiver);
	    	super.onDestroy();
	    }
	    
	    public void sendBroadCast(View v){
	    	new Thread(){
				@Override
				public void run() {
					int count=0;
					//开启一个线程，发送定时广播；
					while(count<=50){
						Intent intent=new Intent(ACTION_TIMER);
						intent.putExtra(EXTRA_TEXT, count++);
						sendBroadcast(intent,ACTION_PERMISSION);
						
						try {
							Thread.sleep(2000);
						} catch (InterruptedException e) {
							e.printStackTrace();
						}
					}
				}
			}.start();
		}
		
MyBroadCastReceiver.java
	
	    public class MyBroadCastReceiver extends BroadcastReceiver{
			@Override
			public void onReceive(Context context, Intent intent) {
			//接收发送的信息
				int count = intent.getIntExtra(EXTRA_TEXT, 0);
				countId.setText(String.valueOf(count));
			}
	    }
	}

若是有权限定义则需要在，mainifest文件中定义和使用权限

	<permission android:name="com.example.broadreciver04.timer.PERMISSION"/>
	    <uses-permission android:name="com.example.broadreciver04.timer.PERMISSION"/>

![android_broadcastreceiver04.png]({{site.baseurl}}/public/img/android_broadcastreceiver04.png)

- 接收和系统广播接收一样，继承BroadCastReceiver,实现onReceive(Context context,Intent intent);BroadCastReceiver05

MainActivity.java直接静态注册Receiver

	public class MyReceiver05 extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {
			Log.i("info05", "当前计数："+intent.getIntExtra("text", 0));
		}
	}
	
AndroidManifest.xml:同样若有权限，则需要声明使用权限

	<uses-permission android:name="com.example.broadreciver04.timer.PERMISSION"/>
	<!-- 注册广播接收器，用来接受04中的广播 -->
        <receiver android:name="com.example.broadcastreceiver05.MyReceiver05" android:permission="com.example.broadreciver04.timer.PERMISSION">
            <intent-filter>
                <action android:name="com.example.broadreciver04.timer"/>
            </intent-filter>
        </receiver>
	

![android_broadcastreceiver05.png]({{site.baseurl}}/public/img/android_broadcastreceiver05.png)

另外：在广播的时候

- intent.setPackage(String packageName):设置广播**发送**的所在包名称
- 注册文件中：android:exported="false":同样可以设置是否**接收**访问以外的包名称

### 使用LocalBroadcastManager发送本地广播；
- LocalBroadcastManager位于support包中的类，用来管理本地（自己的APP程序）的广播的发送
- 相对于全局的广播更加的高效
- 通过LocalBroadcastManager.getInstance(Context)实例化对象；通过register注册和unregister取消注册；通过sendBroadcast(Intent)发送
	
	<nobr/>
	
		public class MainActivity extends Activity {
			private static String ACTION_NAME="com.example.broadcastreceiver06.Action";
			private static String EXTRA_INFO="info";
			
			private TextView msgView;
			BroadcastReceiver myReciver;
			//support包中的本地广播管理；
			LocalBroadcastManager localBcastMgr;
		
			@Override
		    protected void onCreate(Bundle savedInstanceState) {
		        super.onCreate(savedInstanceState);
		        setContentView(R.layout.activity_main);
		        msgView=(TextView) findViewById(R.id.msgTv);
		        
		        //初始化本地广播管理器
		        localBcastMgr=LocalBroadcastManager.getInstance(getApplicationContext());
		        
		        //注册广播
		        myReciver = new MyBroadcastReceiver();
		        localBcastMgr.registerReceiver(myReciver, new IntentFilter(ACTION_NAME));
			}
		
			@Override
			protected void onDestroy() {
				localBcastMgr.unregisterReceiver(myReciver);
				super.onDestroy();
			}
			
		    public void send(View v){
		    	Intent intent=new Intent(ACTION_NAME);
		    	intent.putExtra(EXTRA_INFO, "LocalBroadcastManager：本地广播"+new Date());
		    	
		    	//发送广播
		    	localBcastMgr.sendBroadcast(intent);
		    	
		    	
		    }
		    
		    //创建广播接收器
		    class MyBroadcastReceiver extends BroadcastReceiver{
		
				@Override
				public void onReceive(Context context, Intent intent) {
					msgView.setText(intent.getStringExtra(EXTRA_INFO));
				}
		    	
		    }
		}

同样，运行结果如图：

![android_broadcastreceiver06.png]({{site.baseurl}}/public/img/android_broadcastreceiver06.png)


### 有序广播；
上面介绍的都是普通的广播，此广播的接收属于异步的方式；接下来的有序广播提供了一个广播的接收序列，是有顺序的，期间可以终止(abortBroadcast)接受；

定义三个接受广播

- 通过intent.getStringExtra()取得参数值
- setResultExtras(bundle)：设置传递到下个Receiver的Bundle值
- getResultExtras(true)：取得上个Receiver传递过来的Bundle对象；true则创建的是一个无数据的map；false则内部声明的是一个map指向null的引用；
- abortBroadcast():是终止当前的顺序传递；

FirstReceiver.java

	public class FirstReceiver extends BroadcastReceiver {
	
		@Override
		public void onReceive(Context context, Intent intent) {
			
			String msg = intent.getStringExtra("msg");
			Log.i("info",msg+" @FirstReceiver");
			Bundle bundle=new Bundle();
			bundle.putString("msg", msg);
	
			//将 Bundle 设置给下个Receiver
			setResultExtras(bundle);
		}
	}

SecondReceiver.java
	
	public class SecondReceiver extends BroadcastReceiver {
	
		@Override
		public void onReceive(Context context, Intent intent) {
			
			String msg = getResultExtras(true).getString("msg");
			Log.i("info",msg+" @SecondReceiver");
			Bundle bundle=new Bundle();
			bundle.putString("msg", msg);
	
			//将 Bundle 设置给下个Receiver
			setResultExtras(bundle);
			
			abortBroadcast();
		}
	
	}
	
ThirdReceiver.java
	
	public class ThirdReceiver extends BroadcastReceiver {
	
		@Override
		public void onReceive(Context context, Intent intent) {
			
			String msg = getResultExtras(true).getString("msg");
			Log.i("info",msg+" @ThirdReceiver");
			Bundle bundle=new Bundle();
			bundle.putString("msg", msg);
		}
	
	}

在配置文件中注册权限(permission)和优先级(android:priority)

	<receiver android:name="com.example.receiver.FirstReceiver">
	            <intent-filter android:priority="100">
	                <action android:name="com.example.receiver.BROADCASTRECEIVER"/>
	            </intent-filter>
	        </receiver>
	        <receiver android:name="com.example.receiver.SecondReceiver">
	            <intent-filter android:priority="99">
	                <action android:name="com.example.receiver.BROADCASTRECEIVER"/>
	            </intent-filter>
	        </receiver>
	        <receiver android:name="com.example.receiver.ThirdReceiver">
	            <intent-filter android:priority="98">
	                <action android:name="com.example.receiver.BROADCASTRECEIVER"/>
	            </intent-filter>
	        </receiver>

发送广播

- 通过intent中方法putExtra()值传递数据和对象
- sendOrderedBroadcast(Intent intent,String permission):发送序列广播

<nobr/>

	public class MainActivity extends Activity {
	
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	    }
	    
	    public void send(View v){
	    	Intent intent = new Intent("com.example.receiver.BROADCASTRECEIVER");
	        intent.putExtra("msg", "hello receiver");
	        sendOrderedBroadcast(intent,"com.example.receiver.PERMISSION");
	    }
	}


![android_broadcastreceiver07.png]({{site.baseurl}}/public/img/android_broadcastreceiver07.png)

abortBroadcast阻塞传播

![android_broadcastreceiver08.png]({{site.baseurl}}/public/img/android_broadcastreceiver08.png)




