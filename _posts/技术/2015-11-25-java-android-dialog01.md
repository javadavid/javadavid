---
layout: post
title:  "Android Dialog 学习记录(1) - 普通对话框"
date: 2015/11/25 17:23:43 
categories:
- 技术
tags:
- Android
---

### 作用：

用于显示对话框（多选，单选，确认对话框等自定义对话框）

### 继承关系：
	
	java.lang.Object
  		android.app.Dialog	//对话框的基本类
     		android.app.AlertDialog		//



### 代码（确认对话，单选，多选）

	public class MainActivity extends Activity {
		private Dialog dialog;
		
		private Dialog dialogColor;
		private ArrayAdapter<String> adapter;
		private TextView textView;
		
		private Dialog dialogFontSize;
		private float[] fontSize={15f,20f,25f,30f};
		
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			
			//颜色适配器
			adapter=new ArrayAdapter<String>(getApplicationContext(),R.layout.item_color);
			adapter.add("Red");
			adapter.add("Blue");
			adapter.add("Yellow");
			textView=(TextView) findViewById(R.id.tvId);
			
			createDialog();
			createDialogColor();
			createDialogFontSize();
		}
		
		
		private void createDialogFontSize() {
			//实例化 AlertDialog.Builder 创建 对话框参数
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder.setTitle("选择一种字体")
				.setIcon( android.R.drawable.ic_menu_crop )
				.setCancelable(false)	//禁止点击对话框以外的地方关闭对话框
				//设置单选框按钮的选择项
				//.setMultiChoiceItems(itemsId, checkedItems, listener)这个是多选框，同理
				.setSingleChoiceItems(R.array.fontSize, 2,new DialogInterface.OnClickListener(){	//设置单选框的资源列表和单击事件
					@Override
					public void onClick(DialogInterface dialog, int which) {
						setTitle(getResources().getStringArray(R.array.fontSize)[which]);
						textView.setTextSize(fontSize[which]);
						//关闭当前对话框
						dialogFontSize.dismiss();
					}
				});
			dialogFontSize = builder.create();
		}
	
		private void createDialogColor() {
			//实例化 AlertDialog.Builder 创建 对话框参数
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder.setTitle("选择一种颜色").setIcon(R.drawable.ic_launcher)
				.setCancelable(false)	//禁止点击对话框以外的地方关闭对话框
				//设置ListView的选择样式
				.setAdapter(adapter, new DialogInterface.OnClickListener() {	//设置列表的adapter和 点击事件
					@Override
					public void onClick(DialogInterface dialog, int which) {
						setTitle( adapter.getItem(which) );
						switch (which) {
						case 0:
							textView.setBackgroundColor(Color.RED);
							break;
						case 1:
							textView.setBackgroundColor(Color.BLUE);
							break;
						case 2:
							textView.setBackgroundColor(Color.YELLOW);
							break;
						default:
							break;
						}
					}
				});
			dialogColor = builder.create();
		}
	
		private void createDialog() {
			//实例化 AlertDialog.Builder 创建 对话框参数
			AlertDialog.Builder builder = new AlertDialog.Builder(this);
			builder.setTitle("这是标题").setIcon(R.drawable.ic_launcher)
				.setMessage("你确定退出吗?")	//设置头信息
				.setCancelable(false)	//禁止点击对话框以外的地方关闭对话框
				.setPositiveButton("确定", new DialogInterface.OnClickListener(){
					@Override
					public void onClick(DialogInterface dialog, int which) {
						finish();	//结束程序
					}
				})
				.setNegativeButton("取消", null);
			dialog = builder.create();
		}
		
		//当系统按键按下的时候触发事件
		@Override
		public boolean onKeyDown(int keyCode, KeyEvent event) {
			if(keyCode==KeyEvent.KEYCODE_BACK){	//判断是否按下返回键
				dialog.show();
			}
			return super.onKeyDown(keyCode, event);
		}
		
		//启动Dialog
		public void showDialog(View v) {
			dialog.show();
		}
		
		public void showDialogColor(View v) {
			dialogColor.show();
		}
		
		public void showDialogFontSize(View v) {
			dialogFontSize.show();
		}
	}

strings.xml:配置可以用来配置Color、字体的列表
	
	<resources>
	    <string name="app_name">AlertDialog01</string>
	    <string name="action_settings">Settings</string>
	    <string name="hello_world">Hello world!</string>
		<string-array name="fontSize">
		    <item>小号</item>
		    <item>中号</item>
		    <item>大号</item>
		    <item>特大号</item>
		</string-array>
	</resources>

运行截图：

![android_dialog01.PNG]({{site.baseurl}}/public/img/android_dialog01.png)
![android_dialog02.PNG]({{site.baseurl}}/public/img/android_dialog02.png)
![android_dialog03.PNG]({{site.baseurl}}/public/img/android_dialog03.png)


### 代码说明(个人理解)

1. 使用AlertDialog.Builder静态内部类构造Dialog的各种属性
	- setCancelable(boolean cancelable)：设置点击背景是否将对话框关闭
	- onClick（确定和取消对话框）：简单对话框的点击事件
	- setAdapter(ListAdapter adapter, OnClickListener listener)：列表框的监听点击事件
	- setSingleChoiceItems/setMultiChoiceItems(int itemsId, int checkedItem, OnClickListener listener)：单选框和多选框的点击事件
		- itemsId：是选择的Item资源Id
		- checkedItem/checkedItem[]：是默认的选择的选择项或组
		- listener：是监听的事件，需要覆写onClick(DialogInterface dialog, int which)方法（两个参数分别是选择的dialog对象和选择dialog的Item的position）
2. 使用builder.create()实例化Dialog 和 dialog.show()来显示对话框；
3. 其中关闭隐藏对话框的方法dialog.dismiss();
4. getResources()专门取得strings.xml中的资源信息，.getStringArray(int resid)：可以从资源信息取得ID的对象值
5. 在AlertDialog.Builder需要传递的是this对象的Context，具体可以参看以下


### getApplicationContext和this对象的比较

- getApplicationContext:实际上返回的就只有系统启动时候传送过来的Context
	
		protected void attachBaseContext(Context base) {
	        if (mBase != null) {
	            throw new IllegalStateException("Base context already set");
	        }
	        mBase = base;
	    }
	
		...省略代码...
	
		@Override
	    public Context getApplicationContext() {
	        return mBase.getApplicationContext();
	    }


- this:实际上除了Context本身还有一个资源ID的对象，用来渲染对象的Layout

		public Builder(Context context) {
	        this(context, resolveDialogTheme(context, 0));
	    }