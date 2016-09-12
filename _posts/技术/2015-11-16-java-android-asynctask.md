---
layout: post
title:  "Android asyncTask 学习记录 - 异步任务"
date: 2015/11/16 15:45:22 
categories:
- 技术
tags:
- Android
---
### 解释

1、异步任务：使用子线程执行耗时操作，然后通过调用将结果返回给主线程；

异步任务的作用和规则：

>#### 1.主线程不能被阻塞，不能在主线程中执行耗时操作
>
>#### 2.子线程不可以方法UI控件
	
### 实现方法

>#### 是通过handle通信机制，将子线程的数据（结果）传给主线程，android中的线程的通信机制的类AsyncTask；


### 例子说明：

	
1. protected Result doInBackground(Params... params)来实现子线程的调用；
2. protected void onPostExecute(Result result)实现子线程结果的返回；
3. 异步任务的线程必须在主线程执行，子线程通过execute(params)来执行，doInBackground和onPostExecute两步操作；
4. 主线程通常使用cancel(true)执行子线程取消操作；isCancelled()来判断是否被取消：若执行完成则也是一个取消状态

		public class MainActivity extends Activity {
			private ImageView imageView ;
			@Override
			protected void onCreate(Bundle savedInstanceState) {
				super.onCreate(savedInstanceState);
				setContentView(R.layout.activity_main);
				imageView=(ImageView) findViewById(R.id.imgId);
			}
		
			/*
			 * AsyncTask<Params, Progress, Result>
			 * params:子线程中执行方法的参数类型；
			 * progress:子线程中执行任务的进度类型；
			 * result:子线程执行任务的结果类型；
			 */
			class MyTask extends AsyncTask<String, Void, byte[]>{
				@Override
				protected byte[] doInBackground(String... params) {
					// TODO	子线程执行任务的方法
					try{
						//网络解析操作；
						String uri=params[0];
						HttpClient client=new DefaultHttpClient();
						HttpGet get=new HttpGet(uri);
						HttpResponse response=client.execute(get);
						if(response.getStatusLine().getStatusCode()==HttpStatus.SC_OK){
							return EntityUtils.toByteArray(response.getEntity());
						}
					}catch(Exception e ){
						e.printStackTrace();
					}
					return null;
				}
				
				@Override
				protected void onPostExecute(byte[] result) {
					// TODO 子线程返回主线程的方法
					if(result!=null){
						imageView.setImageBitmap(BitmapFactory.decodeByteArray(result, 0, result.length));
					}
				}
			}
			
			public void onShow(View v){
				new MyTask().execute("http://newtab.firefoxchina.cn/img/worldindex/logo.png");
			}

		}

另外需要配置其网络访问权限

	<uses-permission android:name="android.permission.INTERNET"/>

### 其他的覆写方法
	
	onPreExecute()：调用完UI线程后就立即执行，通常用来显示进程对象的初始值。
	doInBackground(Params...)：
	onProgressUpdate(Progress...)：调用异步进度。比如下载的进度条
	publishProgress(Progress...)：回显给主线程的进度。