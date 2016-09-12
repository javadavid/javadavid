---
layout: post
title:  "Android 事件分发"
date: 2016/3/10 13:40:14 
categories:
- 技术
tags:
- Android
---

### 事件分发
对用户触发的事件 如触摸、点击、按动（onTouchEvent、onKeyUp、onKeyDown、onTrackballEvent、onFocusChanged） 等操作的监控分发（控件的执行顺序），通常有ACTION_DOWN、ACTION_UP、ACTION_MOVE、ACTION_CANCEL。

事件分发由外向内分发，父控件 --> 子控件（Activity - Layout - Button）,然后消费事件则是相反由 内部向外部

执行顺序：

- dispatchTouchEvent(MotionEvent event)：分发事件
- onInterceptTouchEvent(MotionEvent event)：阻止事件的分发（只有Layout有此方法）
- onTouchEvent(MotionEvent event)：对事件进行响应；
 

MainActivity:

	public class MainActivity extends Activity {
	
		private static final String TAG = "MainActivity";
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
		}
	
		@Override
		public boolean dispatchTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - dispatchTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.dispatchTouchEvent(event);
		}
	
		@Override
		public boolean onTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - onTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.onTouchEvent(event);
		}
	}

MyLayout：

	public class MyLayout extends LinearLayout{
	
		private static final String TAG = "MyLayout";
		
		public MyLayout(Context context, AttributeSet attrs) {
			super(context, attrs);
		}
	 
		@Override
		public boolean dispatchTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - dispatchTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.dispatchTouchEvent(event);
		}
	
		@Override
		public boolean onInterceptTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - onInterceptTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.onInterceptTouchEvent(event);
		}
		
		@Override
		public boolean onTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - onTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.onTouchEvent(event);
		}
	}

Button：

	public class MyButton extends Button {
	
		private static final String TAG = "MyButton";
		
		public MyButton(Context context, AttributeSet attrs) {
			super(context, attrs);
		}
		
		@Override
		public boolean dispatchTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - dispatchTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.dispatchTouchEvent(event);
		}
	
		@Override
		public boolean onTouchEvent(MotionEvent event) {
			Log.i("info",TAG + " - onTouchEvent - " + EventUtils.getName(  event.getAction()) );
			return super.onTouchEvent(event);
		}
	}
	
EventUtils：
	
	public class EventUtils {
		public static String getName(int action) {
			switch (action) {
				case MotionEvent.ACTION_DOWN:
					return "ACTION_DOWN";
				case MotionEvent.ACTION_UP:
					return "ACTION_UP";
				case MotionEvent.ACTION_MOVE:
					return "ACTION_MOVE";
				case MotionEvent.ACTION_CANCEL:
					return "ACTION_CANCEL";
				default:
					return "";
			}
		}
	}


activity_main.xml：

	<com.example.eventtouch.MyLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	
	    <com.example.eventtouch.MyButton
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="@string/hello_world" />
	
	</com.example.eventtouch.MyLayout>

点击按钮：

![dispatch_event01.png]({{site.baseurl}}/public/img/dispatch_event01.png)


