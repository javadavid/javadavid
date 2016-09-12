---
layout: post
title:  "Android Menu 学习记录"
date: 2015/11/26 17:52:53 
categories:
- 技术
tags:
- Android
---


## Menu控件主要有三种

- ContextMenu：长按控件（例如ListView）出现的列表框
- OptionsItem：系统Menu菜单创建的菜单
- PopupMenu：根据点击的对象定位，显示Menu列表框出现的位置


### ContextMenu

运行如下图显示

![android_contextmenu01.PNG]({{site.baseurl}}/public/img/android_contextmenu01.png)

各个菜单框的触发事件如下：

- onCreateContextMenu(ContextMenu menu, View v, ContextMenuInfo menuInfo)：创建上下文本菜单项 
	- ContextMenu menu：需要显示的快捷菜单
	- View v：是用户选择的界面元素
	- ContextMenuInfo menuInfo：menuInfo是所选择界面元素的额外信息（包括ViewID和Position）
- registerForContextMenu(View view)：向组件注册菜单上下文；(长按触发弹出对话框 触发 onCreateContextMenu)
- onContextItemSelected(MenuItem item)：点击菜单Item发生的事件
	- MenuItem item：上下文本菜单的对象

#### 代码(ListView_ContextMenu)

**menu.xml文件：**

	<menu xmlns:android="http://schemas.android.com/apk/res/android" >
	    <item
	        android:id="@+id/action_add"
	        android:orderInCategory="100"
	        android:showAsAction="never"
	        android:title="增加"/>
	    <item
	        android:id="@+id/action_update"
	        android:orderInCategory="100"
	        android:showAsAction="never"
	        android:title="更新"/>
	    <item
	        android:id="@+id/action_del"
	        android:orderInCategory="100"
	        android:showAsAction="never"
	        android:title="删除"/>
	</menu>

**MainActivity.java：**

	public class MainActivity extends Activity {
		private ListView lv;
		private List<String> datas;
		private ArrayAdapter<String> adapter;
		private int currentPosition;
	
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			datas = new ArrayList<String>();
			lv = (ListView) findViewById(R.id.lvId);
			adapter = new ArrayAdapter<String>(getApplicationContext(),R.layout.item, datas);
			lv.setAdapter(adapter);
			loadData();
			registerForContextMenu(lv); //向组件注册菜单上下文；
		}
	
		private void loadData() {
			for (int i = 0; i < 40; i++) {
				datas.add("person - " + i);
			}
		}
	
		// 点击菜单时候发生的事件
		@Override
		public boolean onContextItemSelected(MenuItem item) {
			switch (item.getItemId()) {
				case R.id.action_add:
					datas.add(currentPosition, "新的Person - "+System.currentTimeMillis());
					break;
				case R.id.action_update:
					datas.set(currentPosition, "修改Person - "+datas.get(currentPosition)+System.currentTimeMillis());
					break;
				case R.id.action_del:
					Toast.makeText(getApplicationContext(), "DEL : "+datas.get(currentPosition), Toast.LENGTH_SHORT).show();
					datas.remove(currentPosition);
					break;
				default:
					break;
			}
			adapter.notifyDataSetChanged();
			return super.onContextItemSelected(item);
		}
	
		@Override
		public void onCreateContextMenu(ContextMenu menu, View v,
				ContextMenuInfo menuInfo) {
			getMenuInflater().inflate(R.menu.item_edit, menu);	//注册item layout
			AdapterContextMenuInfo amenuInfo=(AdapterContextMenuInfo) menuInfo;	//取得item layout的组件对象
			currentPosition = amenuInfo.position;
			super.onCreateContextMenu(menu, v, menuInfo);
		}
	}

#### 具体步骤

1. 在activity的onCreate(...)方法中为一个view注册上下文菜单
2. 在onCreateContextMenuInfo(...)中生成上下文菜单。
3. 在onContextItemSelected(...)中响应上下文菜单项。


#### ContextMenu总结
在ListView中的操作实际上是对其中的List的操作一样； 

![android_contextmenu02.PNG]({{site.baseurl}}/public/img/android_contextmenu02.png)


### OptionsItem
- onCreateOptionsMenu(Menu menu)：创建的事件，通过getMenuInflater().inflate(R.menu.main, menu)来反射Item的对象
- onOptionsItemSelected(MenuItem item)：通过对各个Item的对象判断，触发Item的点击事件

![android_menu01.PNG]({{site.baseurl}}/public/img/android_menu01.png)



### PopupMenu
- 通过PopupMenu(Context context, View anchor)实例化Menu控件，getMenuInflater().inflate(R.menu.main,popm.getMenu())进行反射
- setOnMenuItemClickListener(OnMenuItemClickListener listener)：触发MenuItem的点击事件

![android_menu02.PNG]({{site.baseurl}}/public/img/android_menu02.png)


#### OptionsItem/PopupMenu具体代码

**main.xml(Item 列表)：**

	<menu xmlns:android="http://schemas.android.com/apk/res/android" >
	    <item
	        android:id="@+id/action_settings"
	        android:orderInCategory="100"
	        android:showAsAction="never"
	        android:icon="@android:drawable/ic_menu_send"
	        android:title="@string/action_settings"/>
	    <item
	        android:id="@+id/action_add"
	        android:orderInCategory="101"
	        android:showAsAction="never"
	        android:icon="@android:drawable/ic_menu_add"
	        android:title="增加"/>
	    <item
	        android:id="@+id/action_del"
	        android:orderInCategory="101"
	        android:showAsAction="never"
	        android:icon="@android:drawable/ic_menu_delete"
	        android:title="减少"/>
	</menu>

**activity_main.xml：**

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <Button
	        android:id="@+id/popupMenuId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="显示 popupMenu 列表菜单" 
	        android:onClick="showPopupMenu"/>
	    <TextView
	        android:id="@+id/tvId"
	        android:layout_below="@id/popupMenuId"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"
	        android:gravity="center"
	        android:text="@string/hello_world" />
	</RelativeLayout>

**MainActivity.java：**

	public class MainActivity extends Activity {
		private TextView tvId;
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			tvId=(TextView) findViewById(R.id.tvId);
		}
		
		@Override
		//创建一个Option Menu
		public boolean onCreateOptionsMenu(Menu menu){
			setIconEnable(menu, true);
			getMenuInflater().inflate(R.menu.main, menu);	//创建系统菜单
			return true;
		}
	
		@Override
		//选择Option Menu菜单触发的事件；
		public boolean onOptionsItemSelected(MenuItem item) {
			changeFontSize(item);
			return super.onOptionsItemSelected(item);
		}
		
		public void showPopupMenu(View v){
			//第一个参数是context对容器，第二个参数是调用着的锚点
			PopupMenu popm = new PopupMenu(getApplicationContext(), v);
			
			//通过资源menu ID取得 列表的对象；
			getMenuInflater().inflate(R.menu.main,popm.getMenu());
			
			setIconEnable(popm.getMenu(),true);
			
			popm.show();
			
			popm.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
				@Override
				public boolean onMenuItemClick(MenuItem item) {
					changeFontSize(item);
					return false;
				}
			});
		}
		
		//Menu Item的触发事件
		private void changeFontSize(MenuItem item){
			float fontSize=tvId.getTextSize();
			switch (item.getItemId()) {
			case R.id.action_settings:
				startActivity(new Intent(Settings.ACTION_SETTINGS));
				break;
			case R.id.action_add:
				fontSize+=5;
				tvId.setTextSize(fontSize);
				break;
			case R.id.action_del:
				fontSize-=5;
				tvId.setTextSize(fontSize);
				break;
			default:
				break;
			}
		}
		
		//通过反射调用 显示菜单Item图标文件
		public void setIconEnable(Menu menu,boolean enable){
			try {
				Class clazz=Class.forName("com.android.internal.view.menu.MenuBuilder");
				Method m=clazz.getDeclaredMethod("setOptionalIconsVisible", boolean.class);
				m.setAccessible(true);
				m.invoke(menu, enable);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

关于设置Item的图标问题：

在3.0以后图标设置失效，需要对象com.android.internal.view.menu.MenuBuilder中的setOptionalIconsVisible方法反射调用。
