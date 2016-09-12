---
layout: post
title:  "Android Dialog 学习记录(2) - 自定义对话框、进度对话框(ProcessDialog)"
date: 2015/11/26 9:14:34 
categories:
- 技术
tags:
- Android
---

### 自定义对话框基本用法

1. 构造一个子控件
2. 使用setView(View v)：来设置到AlertDialog.Bulider中。

代码布局文件
	
	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	
	    <TextView
	        android:id="@+id/nametvId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="姓名：" />
	
	    <EditText
	        android:id="@+id/nameETId"
	        android:textColor="#000"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:inputType="text"
	        android:layout_toRightOf="@id/nametvId"
	        android:layout_alignBaseline="@id/nametvId"
	        android:hint="点击输入姓名"/>  
	    
	    <TextView
	        android:id="@+id/teltvId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:layout_below="@+id/nameETId"
	        android:layout_toLeftOf="@+id/nameETId"
	        android:text="电话：" />
	    
	    <EditText
	        android:id="@+id/telETId"
	        android:textColor="#000"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:layout_toRightOf="@id/teltvId"
	        android:layout_alignBaseline="@id/teltvId"
	        android:inputType="textPhonetic"
	        android:hint="点击输入电话"/>

	</RelativeLayout>

>android:hint="点击输入姓名"：是显示提示信息；

MainActivity：

	public class MainActivity extends Activity {
		private Dialog customDialog;
		private TextView msgView;
		private View v;
		
		private EditText nameETid,telEVid;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			msgView=(TextView) findViewById(R.id.msgViewId);
			initDialog();
		}
	
		private void initDialog() {
			v = LayoutInflater.from(getApplicationContext()).inflate(R.layout.item_dialog, null);
			nameETid= (EditText) v.findViewById(R.id.nameETId);
			telEVid= (EditText) v.findViewById(R.id.telETId);
			AlertDialog.Builder builder=new Builder(this);
			builder.setTitle("设置你的信息")
				.setView(v)
				.setCancelable(false)
				.setPositiveButton("确定",new DialogInterface.OnClickListener(){
					@Override
					public void onClick(DialogInterface dialog, int which) {
						msgView.setText(nameETid.getText()+"\n"+telEVid.getText());
					}
				});
			customDialog=builder.create();
		}
		
		public void setMsg(View view){
			msgView.setText("");
			customDialog.show();
		}
	}

- 主要是通过AlertDialog.Builder.setView(View view)将控件设置到其中；

![android_dialog04.PNG]({{site.baseurl}}/public/img/android_dialog04.png)

### 进度对话框(ProcessDialog)

	public class MainActivity extends Activity {
		private ImageView imgView;
		private ProgressDialog progressDialog;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			imgView=(ImageView) findViewById(R.id.imgView);
			initDialog();
		}
	
		private void initDialog() {
			progressDialog=new ProgressDialog(this);
			progressDialog.setTitle("下载提示");
			progressDialog.setIcon(android.R.drawable.ic_menu_add);
			progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
			progressDialog.setCanceledOnTouchOutside(false);
		}
	
		public void showImg(View view){
			new ImageTask().execute("http://avatar.csdn.net/1/4/F/1_yanzi1225627.jpg");
		}
		
		class ImageTask extends AsyncTask<String, Void, Bitmap>{
			@Override
			protected void onPreExecute() {
				progressDialog.show();
				progressDialog.setProgress(0);
			}
			
			@Override
			protected Bitmap doInBackground(String... params) {
				try {
					URL url=new URL(params[0]);
					HttpURLConnection conn = (HttpURLConnection)url.openConnection();
					if(conn.getResponseCode()==200){
						InputStream stream = conn.getInputStream();	//正式连接（若文件过大则 自动会准换成GZIPInputStream） 造成获  getContentLength=-1
						
						byte[] buff=new byte[stream.available()];
						int len=-1;
						int currlen=0;
						int maxlen=conn.getContentLength();
						
						ByteArrayOutputStream baos=new ByteArrayOutputStream();	//内存流
						while ((len=stream.read())!=-1) {
							baos.write(buff,0,len);
							currlen+=len;
							int progress = currlen*100/maxlen;
							progressDialog.setProgress(progress);
							Thread.sleep(100);
						}
						Log.i("info", " msg："+baos.toByteArray().length);
						return BitmapFactory.decodeByteArray(baos.toByteArray(),0,baos.toByteArray().length);
					}
				} catch (Exception e) {
					e.printStackTrace();
				}
				return null;
			}
			
			@Override
			protected void onPostExecute(Bitmap result){
				progressDialog.dismiss();
				if(result!=null){
					imgView.setImageBitmap(result);
				}
			}
		}
	}

说明：

- 通过点击创建一个子线程，下载图片
- 放到内存流中存取进度，显示对话框进度
- 读取全部读取完成后，返回给ImageView中。并且关闭对话框

截图：

![android_dialog05.PNG]({{site.baseurl}}/public/img/android_dialog05.png)