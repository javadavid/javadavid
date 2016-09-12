---
layout: post
title:  "Android adapter适配器 学习记录 - 简单理解"
date: 2015/11/17 8:52:17  
categories:
- 技术
tags:
- Android
---

## 解释

>adapter是用来实现控件的数据列表的一个接口；

常用的子类实现的List列表

- ArrayAdapter：管理ListView列表
- SpinnerAdapter：管理Spinner的控件列表
- SimpleAdapter：管理像CheckBox、TextView、ImageView列表，会自动调用各自的绑定方法；

下面拿SimpleAdapter做实例

继承关系：

	java.lang.Object
	  android.widget.BaseAdapter
	      android.widget.SimpleAdapter

SimpleAdapter构造：
	
	String[] from, int[] to) 
	context：传入的对象上下文
	data：存放的对象列表
	resource：读取关联列表layout文件；
	from：map列表中的 键
	to：map列表中的 键所对应的layout文件中的ID
	SimpleAdapter(Context context, List<? extends Map<String,?>> data, int resource, String[] from, int[] to) 


### 代码实现：

说明：通过声明数据对象类型，并且构造adapter（将item layout布局文件和数据键值对放进去），最后将adapter放到空间adapter中；

	public class MainActivity extends Activity {
		private Spinner sp;
		private List<Map<String,Object>> datas;
		private Adapter adapter;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			sp=(Spinner) findViewById(R.id.spid);
			//载入数据
			loadData();
			adapter= new SimpleAdapter(getApplicationContext(),datas,R.layout.item_person, 
					new String[]{"name","age","sex"},		//对应的传入的对象数组
					new int[]{R.id.nameId,R.id.ageId,R.id.sexId});	//传给对象View的对应ID
			
			sp.setAdapter((SpinnerAdapter) adapter);		//向下转型设置spinner的列表对象
		}
		
		private void loadData() {
			datas =new ArrayList<Map<String,Object>>();
			for(int i=0;i<4;i++){
				Map<String,Object> map=new HashMap<String,Object>();
				map.put("name", "张三");
				map.put("age", i);
				map.put("sex", i%2==0?"男":"女");
				datas.add(map);
			}
		}
	}


在主布局文件中定义一个spinner控件；

布局文件item_person.xml
	
	<ImageView
        android:id="@+id/imgId"
        android:layout_width="20pt"
        android:layout_height="20pt"
        android:src="@drawable/ic_launcher"/>
	<TextView
	    android:id="@+id/nameId"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_toRightOf="@id/imgId"
        android:text="nameId"/>
	
	<TextView
	    android:id="@+id/ageId"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_toRightOf="@id/imgId"
        android:layout_below="@id/nameId"
        android:text="ageId"/>
	<TextView
	    android:id="@+id/sexId"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_toRightOf="@id/imgId"
        android:layout_below="@id/ageId"
        android:text="sexId"/>


实现效果如下图显示

![android_adapter01]({{site.baseurl}}/public/img/android_adapter01.png)