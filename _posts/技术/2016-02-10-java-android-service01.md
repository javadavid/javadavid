---
layout: post
title:  "Android Service 学习(1)"
date: 2016/2/10 10:02:46 
categories:
- 技术
tags:
- Android
---

### Service服务
属于后台运行的一个子线程，可以长时间的保存用于管理组件，一般不依赖用户界面；用来管理线程生命周期：启动和停止线程；

#### 创建service子类的；重写生命周期；
- onCreate():初始化Service组件（一次）
- onStartCommand():启动服务执行的方法（多次）
- onDestroy():销毁service服务（一次）

#### 注册Serice组件
在配置文件AndroidManifest.xml中注册组件<service android:name="{serivce名称}"/>

#### 启动组件(Activity、BroadcastReceiver、Service组件内部)
Context.startSerivice(Intent intent): intent指向启动组件的class

> 组件启动第一次创建执行、若存在则不需要创建，直接执行onStartCommand

MyService.java:创建Service，复写生命周期;

	public class MyService extends Service {
	
		@Override
		public IBinder onBind(Intent intent) {
			//绑定生命周期的方法
			return null;
		}
		
		@Override
		public void onCreate() {
			//初始化
			super.onCreate();
			Log.i("info", "-- onCreate --");
			
		}
		
		@Override
		public int onStartCommand(Intent intent, int flags, int startId) {
			//启动Service
			Log.i("info", "-- onStartCommand --"+ intent.getExtras().getString("msg"));
			return super.onStartCommand(intent, flags, startId);
		}
		
		@Override
		public void onDestroy() {
			//销毁
			super.onDestroy();
			Log.i("info", "-- onDestroy --");
		}
	}
	
注册Service组件

	<service android:name="com.example.service01.MyService"/>

启动和停止Service

- Context.startService(Intent):启动相应Service意图
- Context.stopService(Intent):停止相应Service意图

<nobr/>

	public class MainActivity extends Activity {
	
		private Intent myServiceIntent;
		
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        myServiceIntent=new Intent(getApplicationContext(),MyService.class);
	    }
	 
	    public void startService(View v){
	    	myServiceIntent.putExtra("msg","msg - "+System.currentTimeMillis());
	    	startService(myServiceIntent);
	    }
	    
	    public void stopService(View v){
	    	stopService(myServiceIntent);
	    }
	}

![android_service01.png]({{site.baseurl}}/public/img/android_service01.png)

### Service服务播放MediaPlayer（Service02_MediaPlayer）
实例化MediaPlayer：可以通过构造和create()方法创建

> 参数一：Context对象、参数二：播放文件的资源ID:一般放在raw文件夹中，通过id可以取得；

- create()方法已经实现了prepare()方法；其中需要销毁release()方法对实例释放；
- 通过广播对进度条和media实体类通知 改变状态 实现进度条的功能

MyMediaPlayer.java:

- onCreate:实现mediaPlayer实例化；和注册MediaPlayer状态广播、实例化接受SeekBar的状态广播
- onStartCommand:其中子线程，子线程用来发送一个广播；通知主线程界面来改变SeekBar的max和progress值
- onDestroy：销毁、停止和回收MediaPlayer资源(同时会销毁子线程)；解注册SeekBar BroadCastReceiver的监听

<nobr/>

	public class MyMediaPlayer extends Service {
		MediaPlayer myPlayer;
		SeekReceiver seekReceiver;
		
		@Override
		public IBinder onBind(Intent intent) {
			// TODO Auto-generated method stub
			return null;
		}
	
		@Override
		public void onCreate() {
			super.onCreate();
			//创建MediaPlayer，其中已经实现prepare()方法；在销毁必须release()释放方法；
			myPlayer = MediaPlayer.create(getApplicationContext(), R.raw.a1);
			
			seekReceiver = new SeekReceiver();
			registerReceiver(seekReceiver, new IntentFilter(Config.ACTION_SEEK_BROADCAST));
		}
		
		@Override
		public int onStartCommand(Intent intent, int flags, int startId) {
			if(myPlayer.isPlaying()){
				myPlayer.pause();
			}else{
				myPlayer.start();
				new ProgressThread().start();
			}
			return super.onStartCommand(intent, flags, startId);
		}
		
		@Override
		public void onDestroy() {
			super.onDestroy();
			myPlayer.stop();
			//myPlayer.release();	//回收资源
			unregisterReceiver(seekReceiver);
		}
		
		//子线程向主线程发送的进度广播
		class ProgressThread extends Thread{
			@Override
			public void run() {
				while(myPlayer!=null && myPlayer.isPlaying()){
					Intent intent = new Intent(Config.ACTION_PROG_BROADCAST);
	
					//取得当前播放位置
					intent.putExtra(Config.CURRENT_POSITION, myPlayer.getCurrentPosition());
	
					//取得播放音乐的持续时间
					intent.putExtra(Config.MAX_LEN, myPlayer.getDuration());
	
					sendBroadcast(intent);
				}
			}
		}
		
		class SeekReceiver extends BroadcastReceiver{
			
			@Override
			public void onReceive(Context context, Intent intent) {
				int currentPosition = intent.getIntExtra(Config.ACTION_SEEK_BROADCAST,0);
				if(myPlayer!=null)
					myPlayer.seekTo(currentPosition);
			}
		}
	}


MainActivity.java：

- onCreate：初始化主界面 、实例化接受mediaPlayer service进度的广播 和 注册SeekBar进度条的广播
	- seekBar.setOnSeekBarChangeListener：seekBar的状态改变的监听状态方法；拖动开始、拖动中和拖动结束(拖动结束：注册SeekBar发送进度广播)
- onDestroy：销毁方法，解注册广播
- 通过按钮来创建启动销毁service意图；

<nobr/>

	public class MainActivity extends Activity {
		Intent playerIntent;
		SeekBar seekBar;
		ProgressReceiver progressReceiver;
		
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        seekBar = (SeekBar) findViewById(R.id.seekBarId);
	        
	        progressReceiver=new ProgressReceiver();
	        registerReceiver(progressReceiver, new IntentFilter(Config.ACTION_PROG_BROADCAST));
	        
	        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
				
				@Override
				public void onStopTrackingTouch(SeekBar seekBar) {
					// TODO 拖动结束的事件
					int progress = seekBar.getProgress();
					Intent intent = new Intent(Config.ACTION_SEEK_BROADCAST);
					intent.putExtra(Config.ACTION_SEEK_BROADCAST, progress);
					
					sendBroadcast(intent);
	
				}
				
				@Override
				public void onStartTrackingTouch(SeekBar seekBar) {
					// TODO 开始拖动
				}
				
				@Override
				public void onProgressChanged(SeekBar seekBar, int progress,boolean fromUser) {
					// TODO 正在拖动之中
				}
			});
	    }
	    
	    @Override
	    protected void onDestroy() {
	    	super.onDestroy();
	    	unregisterReceiver(progressReceiver);
	    }
	    
	    public void start(View v){
	    	playerIntent=new Intent(getApplicationContext(),MyMediaPlayer.class);
	    	startService(playerIntent);
	    }
	    
	    public void stop(View v){
	    	stopService(playerIntent);
	    }
	    
	    
	    //用来接受service中广播发送的当前播放进度数据
		class ProgressReceiver extends BroadcastReceiver{
	
			@Override
			public void onReceive(Context context, Intent intent) {
				int currentPosition = intent.getIntExtra(Config.CURRENT_POSITION,0);
				int maxLen = intent.getIntExtra(Config.MAX_LEN,0);
				
				seekBar.setMax(maxLen);
				seekBar.setProgress(currentPosition);
			}
	    }
	}

config.java 配置信息文件

	public class Config {
		//进度广播
		public static final String ACTION_PROG_BROADCAST="com.example.service02_mediaplayer.progress";
		
		//拖动广播,指定位置
		public static final String ACTION_SEEK_BROADCAST="com.example.service02_mediaplayer.seek";
		
		public static final String CURRENT_POSITION="current";
		public static final String MAX_LEN="max";
	}

布局文件activity_main.xml

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	
	    <Button
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:onClick="start"
	        android:text="开启音乐" />
	
	    <Button
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:onClick="stop"
	        android:text="停止音乐" />
	
	    <!-- 可以拖动的进度条 -->
	
	    <SeekBar
	        android:id="@+id/seekBarId"
	        android:layout_width="fill_parent"
	        android:layout_height="wrap_content"/>
	
	</LinearLayout>


![android_service02.png]({{site.baseurl}}/public/img/android_service02.png)

#### 播放MediaPlayer显示播放时间
上述例子 当拖动滚动条时候存在进度条的监听广播，所以会造成卡顿的现象；
解决方法：在开始拖动SeekBar取消注册；停止后恢复注册progressReceiver

MediaPlayer生命周期：

![android_service.png](http://dl.iteye.com/upload/picture/pic/71458/c6e1ec01-5320-3483-9e0b-6c6f53419880.gif)

	@Override
	public void onStopTrackingTouch(SeekBar seekBar) {
		// TODO 拖动结束的事件
		int progress = seekBar.getProgress();
		Intent intent = new Intent(Config.ACTION_SEEK_BROADCAST);
		intent.putExtra(Config.ACTION_SEEK_BROADCAST, progress);
		
		sendBroadcast(intent);
		//拖动结束回复注册
		registerReceiver(progressReceiver, new IntentFilter(Config.ACTION_PROG_BROADCAST));
	}
		
	@Override
	public void onStartTrackingTouch(SeekBar seekBar) {
		// TODO 开始拖动
		//开始拖动取消注册，防止卡顿
		unregisterReceiver(progressReceiver);
	}

#### MediaPlayer切换歌曲
- 创建文件列表ListView,通过LoaderCallbacks接口回调载入Cursor数据
- ContentProvider音乐字段(MediaColumns)
	- DISPLAY_NAME:歌曲显示名称
	- DATA:歌曲文件绝对路径；
- 切换数据源
	- 增加listView点击事件，通过启动service，判断传入相应的Intent Extra标识改变状态
	- 后台服务onStartCommand判断标识 重置数据源（stop - reset - setDataource - prepare - start ）
	- 最后启动广播线程；

修改后的MainActivity

	public class MainActivity extends Activity implements LoaderCallbacks<Cursor>{
		Intent playerIntent;
		SeekBar seekBar;
		ProgressReceiver progressReceiver;
		TextView timerId;
		
		//文件列表
		ListView lv;
		Cursor cursor;
		SimpleCursorAdapter adapter;
		
		//音乐文件Provider接口字段；
		String colums[] = {MediaColumns._ID,MediaColumns.DISPLAY_NAME,MediaColumns.DATA};
		
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        seekBar = (SeekBar) findViewById(R.id.seekBarId);
	        timerId = (TextView) findViewById(R.id.timerId);
	        lv = (ListView) findViewById(R.id.listViewId);
	        adapter = new SimpleCursorAdapter(getApplicationContext(), R.layout.item_layout, cursor, 
	        		new String[]{colums[1],colums[2]}, 
	        		new int[]{R.id.fileName,R.id.fileUrl},
	        		SimpleCursorAdapter.FLAG_REGISTER_CONTENT_OBSERVER);
	        
	        lv.setAdapter(adapter);
	        getLoaderManager().initLoader(1, null, this);
	        
	        lv.setOnItemClickListener(new AdapterView.OnItemClickListener() {
				@Override
				public void onItemClick(AdapterView<?> parent, View view,
						int position, long id) {
					playerIntent.putExtra(Config.EXTRA_CHANGED, true);
			
					cursor.moveToPosition(position);
			
					String path = cursor.getString(2);
					playerIntent.putExtra(Config.EXTRA_PATH, path);
					
					startService(playerIntent);
				}
	        	
			});
	        
	        progressReceiver=new ProgressReceiver();
	        registerReceiver(progressReceiver, new IntentFilter(Config.ACTION_PROG_BROADCAST));
	        
	        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
				
				@Override
				public void onStopTrackingTouch(SeekBar seekBar) {
					// TODO 拖动结束的事件
					int progress = seekBar.getProgress();
					Intent intent = new Intent(Config.ACTION_SEEK_BROADCAST);
					intent.putExtra(Config.ACTION_SEEK_BROADCAST, progress);
					
					sendBroadcast(intent);
					//拖动结束回复注册
					registerReceiver(progressReceiver, new IntentFilter(Config.ACTION_PROG_BROADCAST));
				}
				
				@Override
				public void onStartTrackingTouch(SeekBar seekBar) {
					// TODO 开始拖动
					//开始拖动取消注册，防止卡顿
					unregisterReceiver(progressReceiver);
				}
				
				@Override
				public void onProgressChanged(SeekBar seekBar, int progress,boolean fromUser) {
					// TODO 正在拖动之中
				}
			});
	    }
	    
	    @Override
	    protected void onDestroy() {
	    	super.onDestroy();
	    	unregisterReceiver(progressReceiver);
	    }
	    
	    public void start(View v){
	    	playerIntent=new Intent(getApplicationContext(),MyMediaPlayer.class);
	    	startService(playerIntent);
	    }
	    
	    public void stop(View v){
	    	stopService(playerIntent);
	    }
	    
	    
	    //用来接受service中广播发送的当前播放进度数据
		class ProgressReceiver extends BroadcastReceiver{
	
			@Override
			public void onReceive(Context context, Intent intent) {
				int currentPosition = intent.getIntExtra(Config.CURRENT_POSITION,0);
				int maxLen = intent.getIntExtra(Config.MAX_LEN,0);
				
				seekBar.setMax(maxLen);
				seekBar.setProgress(currentPosition);
				
				timerId.setText(currentPosition/1000+"--"+maxLen/1000);
			}
	    }
	
	
		@Override
		public Loader<Cursor> onCreateLoader(int id, Bundle bundle) {
			// TODO Auto-generated method stub
			return new CursorLoader(getApplicationContext(), 
					MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,	//从扩展卡下读取所有的音频文件；
					colums, null, null, null);
		}
	
		@Override
		public void onLoadFinished(Loader<Cursor> loader, Cursor cursor) {
			// TODO Auto-generated method stub
			adapter.swapCursor(cursor);
			this.cursor= cursor;
		}
	
		@Override
		public void onLoaderReset(Loader<Cursor> loader) {
			// TODO Auto-generated method stub
			adapter.swapCursor(null);
		}
	}


service组件 MyMediaPlayer.java

	public class MyMediaPlayer extends Service {
		MediaPlayer myPlayer;
		SeekReceiver seekReceiver;
		
		@Override
		public IBinder onBind(Intent intent) {
			// TODO Auto-generated method stub
			return null;
		}
	
		@Override
		public void onCreate() {
			super.onCreate();
			//创建MediaPlayer，其中已经实现prepare()方法；在销毁必须release()释放方法；
			myPlayer = MediaPlayer.create(getApplicationContext(), R.raw.a1);
			
			seekReceiver = new SeekReceiver();
			registerReceiver(seekReceiver, new IntentFilter(Config.ACTION_SEEK_BROADCAST));
		}
		
		@Override
		public int onStartCommand(Intent intent, int flags, int startId) {
			if(intent.getBooleanExtra(Config.EXTRA_CHANGED,false)){
				//切换歌曲标识
				myPlayer.stop();
				myPlayer.reset();//重置player
				try {
					//设置元数据
					myPlayer.setDataSource(intent.getStringExtra(Config.EXTRA_PATH));
					myPlayer.prepare();	//设置完成，准备播放
					myPlayer.start();
					
					new ProgressThread().start();	//启动进度条广播
				} catch (IOException e) {
					e.printStackTrace();
				}
			}else{
			
				if(myPlayer.isPlaying()){
					myPlayer.pause();
				}else{
					myPlayer.start();
					new ProgressThread().start();
				}
			}
			return super.onStartCommand(intent, flags, startId);
		}
		
		@Override
		public void onDestroy() {
			super.onDestroy();
			myPlayer.stop();
			//myPlayer.release();	//回收资源
			unregisterReceiver(seekReceiver);
		}
		
		//子线程向主线程发送的进度广播
		class ProgressThread extends Thread{
			@Override
			public void run() {
				while(myPlayer!=null && myPlayer.isPlaying()){
					Intent intent = new Intent(Config.ACTION_PROG_BROADCAST);
	
					//取得当前播放位置
					intent.putExtra(Config.CURRENT_POSITION, myPlayer.getCurrentPosition());
	
					//取得播放音乐的持续时间
					intent.putExtra(Config.MAX_LEN, myPlayer.getDuration());
	
					sendBroadcast(intent);
				}
			}
		}
		
		class SeekReceiver extends BroadcastReceiver{
			
			@Override
			public void onReceive(Context context, Intent intent) {
				int currentPosition = intent.getIntExtra(Config.ACTION_SEEK_BROADCAST,0);
				if(myPlayer!=null)
					myPlayer.seekTo(currentPosition);
			}
		}
	}

配置常亮和Item布局

	public class Config {
		//进度广播
		public static final String ACTION_PROG_BROADCAST="com.example.service02_mediaplayer.progress";
		
		//拖动广播,指定位置
		public static final String ACTION_SEEK_BROADCAST="com.example.service02_mediaplayer.seek";
		
		public static final String CURRENT_POSITION="current";
		public static final String MAX_LEN="max";
		
		
		//主线程通知service是否切换歌曲的常量
		public static final String EXTRA_CHANGED="changed";
		public static final String EXTRA_PATH="path";
	}

<nobr/>

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <TextView 
	        android:id="@+id/fileName"
	        android:layout_width="match_parent"
	    	android:layout_height="wrap_content"
	    	android:textColor="#00f"
	    	android:textSize="20sp" />
	    <TextView 
	        android:id="@+id/fileUrl"
	        android:textColor="#aaa"
	        android:textSize="15sp"
	        android:layout_width="match_parent"
	    	android:layout_height="wrap_content" />
	</LinearLayout>


![android_service03.png]({{site.baseurl}}/public/img/android_service03.png)

#### Service绑定事件(onBind)
实现Service组件和Activity组件的绑定，绑定的Activity可以使用Service中的功能性方法；绑定的Service组件的生命周期随着Activity的变化；

- 创建Service子类，重写绑定操作的相关方法onCreate() - onBind()/返回Binder对象 - onUnBind()/返回值是true则解除绑定，否则不解除绑定 - onReBind() - onDestroy()
- 注册Service到manifest文件中
- Activity绑定组件中的通信接口对象（ServiceConnection接口）；
- Activity中绑定(bindService)或者解绑(unBindService)Service

布局activity_main.xml：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".MainActivity" >
    <Button
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="startService" 
        android:onClick="startService" />
    <Button
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="stopService" 
        android:onClick="stopService" />
    <Button
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="bindService" 
        android:onClick="bindService"/>
	<Button
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="unBindService" 
        android:onClick="unBindService" />
	</LinearLayout>

TimerService.java：service组件 

- 覆写生命周期的方法 启动服务、绑定、取消绑定（重新绑定）、销毁服务 ；
- 定义返回继承Binder对象TimerBinder
- 其中TimerBinder中定义调用方法；这里使用通知（Notification），绑定相应的Timer任务；
- 实例化返回给方法onBind(Intent intent)

<nobr/>

	public class TimerService extends Service {

		private Timer timer;	//定时工具
		
		private NotificationManager notifiyManager;
		
		@Override
		public void onCreate() {
			// TODO Auto-generated method stub
			super.onCreate();
			Log.i("info", " -- onCreate -- ");
			timer = new Timer();
			notifiyManager=(NotificationManager) getSystemService(NOTIFICATION_SERVICE);
		}
		
		@Override
		public IBinder onBind(Intent intent) {
			// TODO 绑定方法；
			Log.i("info", " -- onBind -- ");
			return new TimerBinder();
		}
		
		@Override
		public boolean onUnbind(Intent intent) {
			// TODO 解除绑定
			Log.i("info", " -- onUnbind -- ");
			return super.onUnbind(intent);
		}
		
		@Override
		public void onRebind(Intent intent) {
			// TODO 重新绑定
			super.onRebind(intent);
			Log.i("info", " -- onRebind -- ");
		}
		
		@Override
		public void onDestroy() {
			// TODO Auto-generated method stub
			super.onDestroy();
			Log.i("info", " -- onDestroy -- ");
			timer.cancel();timer=null;
		}
		
		//IBinder的子类，向Activity提供功能性方法；
		class TimerBinder extends Binder{
			//启动定时任务
			void startTimer(final String info , long ms){
				timer.schedule(new TimerTask() {
					@Override
					public void run() {
						//显示通知
						NotificationCompat.Builder builder = new NotificationCompat.Builder(getApplicationContext());
						
						builder.setSmallIcon(R.drawable.ic_launcher)
								.setContentTitle("定时提醒")
								.setContentText(info)
								.setTicker(info)
								.setDefaults(Notification.DEFAULT_SOUND);
						notifiyManager.notify(0, builder.build());
					}
				}, ms ,10*1000);
			}
			
			void stopTimer(){
				timer.cancel();
			}
		}
	}


MainActivity.java：	

- 覆写ServiceConnection类中的连接成功（onServiceDisconnected）和连接不成功方法（onServiceConnected）；
- 初始 onCreate 实例化timerIntent对象 
- startService()负责启动 TimerService 中的 onCreate 启动服务
- bindService()负责启动 TimerService 中的 onBind绑定服务；通过Context.bindService(Intent,ServiceConnection,flag)方法传入意图路径，连接状态管理，操作绑定参数
- unBindService()负责 TimerService 中的 onUnbind 取消绑定服务
- stopService()负责 TimerService 中的 销毁服务
	
<nobr/>

	public class MainActivity extends Activity {
	
		//用来监控Service状态的回调方法、连接Service状态；
		private ServiceConnection sconnection = new ServiceConnection() {
			
			@Override
			public void onServiceDisconnected(ComponentName name) {
				// TODO 系统崩溃时候断开服务连接
				Log.i("info", "-- onServiceDisconnected --");
				
			}
			
			@Override
			public void onServiceConnected(ComponentName name, IBinder service) {
				// TODO 绑定组件连接成功
				Log.i("info", "-- onServiceConnected --");
				tBinder =(TimerBinder) service;
				tBinder.startTimer("时间到了。", 5*1000);
			}
		};
		private Intent timerIntent;
		private TimerBinder tBinder;
	    
		@Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        
	        timerIntent=new Intent(getApplicationContext(),TimerService.class);
	        
	    }
	
	    public void bindService(View v){
	    	//绑定服务
	    	bindService(timerIntent, sconnection, BIND_AUTO_CREATE);
	    }
	
	    public void unBindService(View v){
	    	if(tBinder!=null){
	    		tBinder.stopTimer();
	    		tBinder=null;
	    		unbindService(sconnection);
	    	}
	    }
	    
	    public void startService(View v){
	    	startService(timerIntent);
	    }
	    
	    public void stopService(View v){
	    	stopService(timerIntent);
	    }
	}

![android_service04.png]({{site.baseurl}}/public/img/android_service04.png)


可以看出 对于Service中的onBind和onUnbind方法；onBind调用时会自动Service创建，onUnbind则会自动对Service销毁。

-  Service绑定的生命周期中  从创建到绑定和解除绑定 **都只有一次**
-  而在执行的生命周期中  **创建销毁是一次，StartCommand执行可以是多次** 

