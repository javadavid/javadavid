---
layout: post
title:  "Android Handler 学习记录"
date: 2016/1/7 08:00:47 
categories:
- 技术
tags:
- Android
---

### Handler

起到线程之间的通信作用的类；比如主线程和子线程间 

- Looper：循环读取MessageQueue队列的线程列表
- MessageQueue：存放相应的消息
- Handler：对消息发送和处理
- Message：封装通信信息；
- 对于线程的分发执行方法dispatchMessage(Message msg)；
	- 其中msg：绑定了调用方target 和 回调callback

#### 子线程向主线程通信 sendMessage(Message msg)方式

布局文件：activity_main.xml

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" 
	    android:orientation="vertical">
	    <Button
	        android:id="@+id/downBtn"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:onClick="download"
	        android:text="DownLoad" />
	    <ImageView
	        android:id="@+id/imgId"
	        android:layout_width="match_parent"
	        android:layout_height="match_parent" />
	</LinearLayout>

MainActivity.java：

- 点击按钮启动一个子线程
- 通过创建Message将子线程中下载的Bitmap对象发到Message.obj中
- 通过Handler发送给主线程；

<nobr/>

	public class MainActivity extends Activity {
		private ImageView imgView;
		private String uri="http://newtab.firefoxchina.cn/img/sitenav/logo.png";
		
		private Handler handler=new Handler(){
			@Override
			public void handleMessage(Message msg) {
				//主线程接收处理消息
				Bitmap bitmap=(Bitmap) msg.obj;
				imgView.setImageBitmap(bitmap);
			}
		};
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			imgView=(ImageView) findViewById(R.id.imgId);
		}
		
		//子线程向主线程发送消息
		public void download(View view){
			new Thread(){	//创建子线程下载文件
				public void run() {
					try {
						HttpClient client=new DefaultHttpClient();
						HttpResponse response=client.execute(new HttpGet(uri));
						if(response.getStatusLine().getStatusCode() == HttpStatus.SC_OK){
							byte[] bytes=EntityUtils.toByteArray(response.getEntity());
							Bitmap bitmap=BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
							//imgView.setImageBitmap(bitmap);
							
							//通过Handler发送线程给主线程
							Message message=Message.obtain();		//从连接池创建Message对象
							message.obj=bitmap;
							//发送消息
							handler.sendMessage(message);
						}
					} catch (Exception e) {
						e.printStackTrace();
					}
				};
			}.start();
		}
	}

![android_handler01.png]({{site.baseurl}}/public/img/android_handler01.png)

#### 子线程向主线程通信 sendEmptyMessage(int what)方式

实际上和上面的sendMessage一样，都是调用的
**sendMessageDelayed(Message msg, long delayMillis)**

布局文件 activity_main.xml：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <LinearLayout
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:orientation="horizontal" >
	        <Button
	            android:id="@+id/startBtn"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:layout_weight="1"
	            android:onClick="startTime"
	            android:text="开始计时" />
	        <Button
	            android:id="@+id/stopBtn"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:layout_weight="1"
	            android:onClick="stopTime"
	            android:text="停止计时" />
	    </LinearLayout>
	    <TextView
	        android:id="@+id/timeView"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"
	        android:gravity="center"/>
	</LinearLayout>


MainActivity.java：通过方法 sendEmptyMessage(int what) 发送个Handler主线程执行

	public class MainActivity extends Activity {
		private Button startBtn,stopBtn;
		private TextView timeView;
		
		boolean isStart=true;	//是否停止循环的标识
		
		private Handler hander=new Handler(){
			@Override
			public void handleMessage(Message msg) {
				timeView.setText(String.valueOf(msg.what));
			}
		};
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			timeView=(TextView) findViewById(R.id.timeView);
			startBtn=(Button) findViewById(R.id.startBtn);
			stopBtn=(Button) findViewById(R.id.stopBtn);
			stopBtn.setEnabled(false);
			startBtn.setEnabled(true);
		}
		
		public void startTime(View view){
			stopBtn.setEnabled(true);
			startBtn.setEnabled(false);
			
			new Thread(){
				public void run() {
					isStart=true;
					int count=0;
					while(isStart){
						//发送一个空消息给主线程
						hander.sendEmptyMessage(count++);
						try {
							Thread.sleep(1000);
						} catch (InterruptedException e) {
							e.printStackTrace();
						}
					}
				};
			}.start();
		}
		
		//停止计数，但是子线程没有停止
		public void stopTime(View view){
			stopBtn.setEnabled(false);
			startBtn.setEnabled(true);
			isStart=false;	
		}
	}


#### 子线程向主线程通信 Handler.post(Runnable r) 方式

MainActivity.java 子线程代码块 ： 向主线程发送一个线程代码块（此代码块在主线程执行）

	new Thread(){
		public void run() {
			isStart=true;
			count=0;
			while(isStart){
				//使用  post 方式发送数据给主线程 一个线程对象
				hander.post(new Runnable() {
					@Override
					public void run() {
						timeView.setText(String.valueOf(count++));
					}
				});
			}
		};
	}.start();


![android_handler02.png]({{site.baseurl}}/public/img/android_handler02.png)


#### 主线程向子线程通信

MainActivity.java：

- mHandler.sendMessage(msg)：向子线程发送数据 实际上是发送到MessageQueue队列
- Looper.prepare()：此时会创建MessageQueue
- 子线程中 new Handler()：将Handler 中mQueue会指向  创建的MessageQueue列中
- Looper.loop()：循环读取MessageQueue 中的Message对象


<nobr/>

	public class MainActivity extends Activity {
		private Handler mHandler;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			new Connection().start();
			
		}
		public void Threadbtn(View view){
			if(mHandler!=null){
				Message msg=Message.obtain();
				msg.obj="我是主线程；";
				mHandler.sendMessage(msg);	//向子线程发送数据
			}
		}
		class Connection extends Thread{
			@Override
			public void run() {
				Looper.prepare();	//此时会创建MessageQueue
				mHandler=new Handler(){		//将Handler放入到MessageQueue队列中
					@Override
					public void handleMessage(Message msg) {
						Log.i("info", new Date()+"-->"+msg.obj);
					}
				};
				Looper.loop();	//循环读取MessageQueue 中的Message
			}
		}
	}

![android_handler03.png]({{site.baseurl}}/public/img/android_handler03.png)


