---
layout: post
title:  "Android Service 学习(2) - 不同进程间的通信"
date: 2016/2/13 14:09:55 
categories:
- 技术
tags:
- Android
---

### Service 进程间的通信（AIDL）
不同的android进程中无法共享内存，aidl则提供了进程间的通信接口机制，可以调用外部应用程序提供的数据接口 （与webservice机制感觉差不多，需要服务端和客户端之间通信）

#### 服务端：

1. 定义一个aidl文件 CalculateInterface.aidl
	
		package com.example.aidl； 
		interface CalculateInterface {
			double doCalculate(double a, double b);
		}
	
在gen中会生成相应的CalculateInterface.java文件，定义方法如下：

![android_service05.png]({{site.baseurl}}/public/img/android_service05.png)

其中会生成一个接口的实现，并且通过生成的子类存放抽象类，和一个代理类

- 子类Stub的定义，继承了Binder，并且实现了接口

		public static abstract class Stub extends android.os.Binder implements com.example.aidl.CalculateInterface

- asInterface：取得IBinder转换成本地的接口实体 若是本地的Binder则不进行通信了，直接在本地调用（客户端调用）
- onTransact：主要作用是将接口方法中的传入传出参数类型和值 读取和写入到Parcel中；（服务端通过transact方法调用）
	
		case TRANSACTION_doCalculate: {
			data.enforceInterface(DESCRIPTOR);
			double _arg0;
			_arg0 = data.readDouble();
			double _arg1;
			_arg1 = data.readDouble();
			double _result = this.doCalculate(_arg0, _arg1);
			reply.writeNoException();
			reply.writeDouble(_result);
			return true;
		}

- asBinder：用于给代理类调用返回正确的binder对象；


2. 服务返回绑定接口IBinder  CalculateServer.java实例化子类Binder对象，实现接口方法；

		public class CalculateServer extends Service{
	
			@Override
			public IBinder onBind(Intent intent) {
				Log.i("info", "-- onBind --");
				return mBinder;
			}
			
			private final CalculateInterface.Stub mBinder = new CalculateInterface.Stub() {
				
				@Override
				public double doCalculate(double a, double b) throws RemoteException {
					return a+b;
				}
			};
		}

3. 静态声明service配置文件

		<service android:name="com.example.aidl.server.CalculateServer">
		  <intent-filter>
		      <action android:name="com.example.aidl.server.CalculateServer"/>
		  </intent-filter>
		</service>

#### 客户端:

需要同样的aidl文件，与绑定本地服务相似，只不过是隐式声明后的调用绑定

> ServiceConnection连接取得服务 - 启动定义意图  - 绑定后调用服务内容/方法接口

	public class MainActivity extends Activity {
		private EditText num1;
		private EditText num2;
		private TextView result;
		
		private CalculateInterface mService;
		
		private ServiceConnection sConnect = new ServiceConnection() {
			
			@Override
			public void onServiceDisconnected(ComponentName name) {
				Log.i("info", "-- onServiceDisconnected --");
				mService=null;
			}
			
			@Override
			public void onServiceConnected(ComponentName name, IBinder service) {
				Log.i("info", "-- onServiceConnected --");
				//从服务取得service接口
				mService = CalculateInterface.Stub.asInterface(service);
			}
		};
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        Intent intent =new Intent("com.example.aidl.server.CalculateServer");
	        
	        //绑定服务
	       	bindService(intent, sConnect, BIND_AUTO_CREATE);
	        
	        num1=(EditText) findViewById(R.id.num1Id);
	        num2=(EditText) findViewById(R.id.num2Id);
	        result=(TextView) findViewById(R.id.resultId);
	    }
	    
	    public void add(View v){
	    	try {
	    		//调用接口方法返回值给 result TextView
	    		result.setText( String.valueOf(  mService.doCalculate(Double.valueOf(num1.getText().toString()),Double.valueOf(num2.getText().toString())) )) ;
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} 
	    }
	}

布局文件activity_main.xml

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
		android:orientation="vertical"
	    tools:context=".MainActivity" >
	
	    <EditText
	        android:id="@+id/num1Id"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
		<EditText
	        android:id="@+id/num2Id"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
		<Button 
		    android:onClick="add"
		    android:text="远程计算（AIDL）"
		    android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
		<TextView
	        android:id="@+id/resultId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content" />
	</LinearLayout>

![android_service06.png]({{site.baseurl}}/public/img/android_service06.png)


### 使用信使（Messenger）实现IPC通信；
- 服务端
	- 定义Handler取得client准备的数据源
	- 定义Messenger封装handler对象
	- 返回绑定服务的IBinder对象（messenger.getBinder）
- 客户端
	- 通过普通的绑定隐式服务，连接成功得到的服务Binder对象
	- 声明实例化Messenger绑定包装服务
	- 信使Messeger发送Message对象到服务（其中对象发送的对象需要实现了Parcelable接口）

#### 服务端：

	public class PrintService extends Service {
	
		private Handler handler = new Handler(){
			public void handleMessage(android.os.Message msg) {
				switch (msg.what) {
				case 0:
					Log.i("info","正在打印文本 " + msg.getData().getString("txt"));
					break;
				case 1:
					Log.i("info", "正在打印图片 " + msg.getData().getByteArray("bitmap") );
				default:
					break;
				}
			};
		};
		
		private Messenger messenger = new Messenger(handler);
		
		
		@Override
		public IBinder onBind(Intent intent) {
			// TODO Auto-generated method stub
			return messenger.getBinder();
		}
	
	}

声明服务：

	<service android:name="com.example.service05_messenger_server.PrintService">
	  <intent-filter>
	      <action android:name="com.example.service05_messenger.PrintService" />
	  </intent-filter>
	</service>

#### 客户端：

	public class MainActivity extends Activity {
	
		private Messenger messager;
		
		private ServiceConnection sConnection = new ServiceConnection() {
			
			@Override
			public void onServiceDisconnected(ComponentName name) {
				
			}
			
			@Override
			public void onServiceConnected(ComponentName name, IBinder service) {
				Toast.makeText(getApplicationContext(), "连接打印机成功", 0).show();
				messager = new Messenger(service);
			}
		};
		
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	    }
	    
	    public void connectPrint(View v){
	    	//绑定服务;
	    	bindService(new Intent("com.example.service05_messenger.PrintService"), sConnection, BIND_AUTO_CREATE);
	    }
	    
	    public void printImg(View v){
	    	if(!checkIsConnect()){
	    		return ;
	    	}
	    	Message msg = Message.obtain();
	    	msg.what = 0;
	    	Bundle data = new Bundle();
	    	data.putString("txt", "这个是文本对象");
	    	msg.setData(data);
	    	
	    	//msg.obj = "我是文本对象";
	    	try {
				messager.send(msg);
			} catch (RemoteException e) {
				e.printStackTrace();
			}
	    }
	    
	    public void printText(View v){
	    	if(!checkIsConnect()){
	    		return ;
	    	}
	    	Message msg = Message.obtain();
	    	msg.what = 1;
	    	Bundle data = new Bundle() ;
	    	data.putByteArray("bitmap",new byte[(int) Math.random()*1024]);
	    	msg.setData(data);
	    	
	    	//使用信使Messager 就不能使用obj传递Object，因为其没有实现Pracelable接口,Bundle则有实现
	    	//msg.obj = new byte[(int)Math.random()*1024];
	    	try {
				messager.send(msg);
			} catch (RemoteException e) {
				e.printStackTrace();
			}
	    }
	    
	    public boolean checkIsConnect(){
	    	if(messager==null){
	    		Toast.makeText(getApplicationContext(), "当前没有连接打印机", 0).show();
	    		return false;
	    	}
	    	return true;
	    }
	    
	    @Override
	    protected void onDestroy() {
	    	unbindService(sConnection);
	    	super.onDestroy();
	    }
	}

布局文件:

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity">
	    <Button
	        android:onClick="connectPrint"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="连接打印机" />
		<Button
	        android:onClick="printImg"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="打印图片" />
		<Button
	        android:onClick="printText"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="打印文本" />
	</LinearLayout>

![android_service07.png]({{site.baseurl}}/public/img/android_service07.png)

两种进程间通信实现，其中权限的定义一样可以在manifest中定义

- aidl是通过服务取得对数据源处理的结果、是双向的
- 第二种Messenger发送 是客户端像服务端进行连接，服务端应答
	- 若要实现客户端应答，则需要在客户端进行handler接收Messenger处理
	- 客户端：声明一个返回的信使管道 通过 msg.replyTo = replayMessenger;将信使封装到消息中一同发送
 	
			//handle接受信使
			private Handler mHandle = new Handler(){
				public void handleMessage(Message msg) {
					Log.i("info", "客户端接收的数据：" + msg.getData().getString("msg"));
				};
			};
			
			//回传的信使
			private Messenger replayMessenger = new Messenger(mHandle);//handle接受信使
			private Handler mHandle = new Handler(){
				public void handleMessage(Message msg) {
					Log.i("info", "客户端接收的数据：" + msg.getData().getString("msg"));
				};
			};
			
			//回传的信使
			private Messenger replayMessenger = new Messenger(mHandle);

	- 服务端：处理消息后返回给客户端一个消息

			Message replayMsg = Message.obtain();
			Bundle data = new Bundle();
			data.putString("msg", "我是Service返回的数据");
			replayMsg.setData(data);
	
			//取得客户端的发送信使 从服务端在发送给客户端；
			try {
				msg.replyTo.send(replayMsg);
			} catch (RemoteException e) {
				e.printStackTrace();
			}

![android_service08.png]({{site.baseurl}}/public/img/android_service08.png)

