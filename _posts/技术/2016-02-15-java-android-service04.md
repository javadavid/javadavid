---
layout: post
title:  "Android Service - IntentService"
date: 2016/2/15 11:27:54 
categories:
- 技术
tags:
- Android
---

### IntentService
一般sevice是依赖于应用程序的主线程，不会有过多的耗时操作，否则会有无响应的现象；IntentService则是在其中可以在Service创建一个子线程，可以耗时操作。

内部实现：

IntentService首先覆写了Sevice内部的一些生命周期；

- 接受子线程：创建ServiceHandler子类接受存在Looper线程
- 回调方法执行完成后自动销毁`stopSelf`
	
		private final class ServiceHandler extends Handler {
		   public ServiceHandler(Looper looper) {
		       super(looper);
		   }
			
		   @Override
		   public void handleMessage(Message msg) {
		       
		       //调用回调接口，传入的是封装好的intent
		       onHandleIntent((Intent)msg.obj);
		       
		       //根据ID停止相应的Service线程
		       stopSelf(msg.arg1);
		   }
		}


- onStartCommand调用了onStart:	其中创建了一个存在Looper的HandlerThread线程，将其封装到ServiceHandler子类，通过handler发送给子类；

	    @Override
	    public void onCreate() {
	        // TODO: It would be nice to have an option to hold a partial wakelock
	        // during processing, and to have a static startService(Context, Intent)
	        // method that would launch the service & hand off a wakelock.
	
	        super.onCreate();
	        HandlerThread thread = new HandlerThread("IntentService[" + mName + "]");
	        thread.start();
	
	        mServiceLooper = thread.getLooper();
	        mServiceHandler = new ServiceHandler(mServiceLooper);
	    }
	
	    @Override
	    public void onStart(Intent intent, int startId) {
	        Message msg = mServiceHandler.obtainMessage();
	        msg.arg1 = startId;
	        msg.obj = intent;
	        mServiceHandler.sendMessage(msg);
	    }
	    
#### 生命周期：

启动IntentService和Service一样，onCreate - onStartCommand - onHandleIntent（回调接口） - onDestroy；

	public class ImageDownloadService extends IntentService {

	public ImageDownloadService() {
		//指定线程名称；
		super(null);
	}

	@Override
	public void onCreate() {
		super.onCreate();
		Log.i("info", "-- onCreate --");
	}
	
	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		Log.i("info", "-- onStartCommand --");
		return super.onStartCommand(intent, flags, startId);
	}
	
	@Override
	protected void onHandleIntent(Intent intent) {
		Log.i("info", "-- onHandleIntent --");			
	}
	@Override
	public void onDestroy() {
		Log.i("info", "-- onDestroy --");
		super.onDestroy();
	}
}

![android_service10.png]({{site.baseurl}}/public/img/android_service10.png)


#### 使用IntentService下载文件操作：

Service组件：其中所有的执行方法都在onHandleIntent（里面会自动创建一个有hander looper message），创建执行完成后自动关闭，然后使用广播回显给主线程；

	public class ImageDownloadService extends IntentService {
	
		public ImageDownloadService() {
			//指定线程名称；
			super(null);
		}
	
		@Override
		public void onCreate() {
			super.onCreate();
			Log.i("info", "-- onCreate --");
		}
		
		@Override
		public int onStartCommand(Intent intent, int flags, int startId) {
			Log.i("info", "-- onStartCommand --");
			return super.onStartCommand(intent, flags, startId);
		}
		
		@Override
		protected void onHandleIntent(Intent intent) {
			Log.i("info", "-- onHandleIntent --");		
			String path = intent.getStringExtra(Config.EXT_PATH);
			//下载图片
			try {
				HttpURLConnection connect = (HttpURLConnection) new URL(path).openConnection();
				if(connect.getResponseCode() == 200){
					InputStream is = connect.getInputStream();
					byte[] bytes = new byte[is.available()];
					ByteArrayOutputStream baos = new ByteArrayOutputStream();
					int len =-1;
					while((len = is.read(bytes)) !=-1){
						baos.write(bytes, 0, len);
					}
					
					bytes = baos.toByteArray();
					
					
					Intent imgIntent = new Intent(Config.ACTION_IMG);
					imgIntent.putExtra(Config.EXT_IMG, bytes);
					imgIntent.putExtra(Config.EXT_PATH, path);
					sendBroadcast(imgIntent);
					
				}
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
				
		}
		@Override
		public void onDestroy() {
			Log.i("info", "-- onDestroy --");
			super.onDestroy();
		}
	}


布局文件：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" 
	    android:id="@+id/mainId">
	
	    <Button
	        android:onClick="downloadPic"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="Download" />
		<ImageView 
		    android:id="@+id/img1View"
		    android:scaleType="centerCrop"
		    android:layout_width="100dp"
	        android:layout_height="100dp"/>
		<ImageView 
		    android:scaleType="centerCrop"
		    android:id="@+id/img2View"
		    android:layout_width="100dp"
	        android:layout_height="100dp"/>
	</LinearLayout>

主界面：MainActivity.java创建界面启动服务；得到广播数据，设置图片控件的属性；

	public class MainActivity extends Activity {
		Intent intent;
		
		ImageView img1View,img2View;
		ViewGroup parent;
		String urls[] = {"http://v4.vcimg.com/global/images/logo.png","http://bbs.a9vg.com/static/image/common/logo.png"};
	
		MyBroadcast mybroadCast;
		
	    @Override
	    protected void onCreate(Bundle savedInstanceState) {
	        super.onCreate(savedInstanceState);
	        setContentView(R.layout.activity_main);
	        img1View = (ImageView) findViewById(R.id.img1View);
	        img1View.setTag(urls[0]);
	        
	        img2View = (ImageView) findViewById(R.id.img2View);
	        img2View.setTag(urls[1]);
	        
	        parent = (ViewGroup) findViewById(R.id.mainId);
	        
	        intent = new Intent(getApplicationContext(),ImageDownloadService.class);
	        
	        mybroadCast = new MyBroadcast();
	        
	        registerReceiver(mybroadCast, new IntentFilter(Config.ACTION_IMG));
	    }
	
	    
	    public void downloadPic(View v){
	    	img1View.setImageResource(R.drawable.ic_launcher);
	    	img2View.setImageResource(R.drawable.ic_launcher);
	    	
	    	//启动服务
	    	intent.putExtra(Config.EXT_PATH, urls[0]);
	    	startService(intent);
	    	//启动服务
	    	intent.putExtra(Config.EXT_PATH, urls[1]);
	    	startService(intent);
	    }
	    
	    class MyBroadcast extends BroadcastReceiver{
	    	
			@Override
			public void onReceive(Context context, Intent intent) {
				byte[] imgbyte = intent.getByteArrayExtra(Config.EXT_IMG);
				
				ImageView img = (ImageView) parent.findViewWithTag(intent.getStringExtra(Config.EXT_PATH));
				
				if(img!=null)
					img.setImageBitmap(BitmapFactory.decodeByteArray(imgbyte, 0, imgbyte.length));
			}
	    }
	}

![android_service11.png]({{site.baseurl}}/public/img/android_service11.png)

