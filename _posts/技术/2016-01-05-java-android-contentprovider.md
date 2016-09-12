---
layout: post
title:  "Android ContentProvider 学习记录（补充）"
date: 2016/1/5 13:00:00 
categories:
- 技术
tags:
- Android
---

### ContentProvider存储电话记录的位置（URI）

原始数据的存储位置：com.android.providers.contacts  
提供的对外接口：com.android.contacts

adb shell中路径：

/data/data/com.android.providers.contacts/databases/contacts2.db中的table

![android_provider02.png]({{site.baseurl}}/public/img/android_provider02.png)
 

主要的联系人表

- raw_contacts：存放联系人的ID
- mimetypes：存放数据的类型
- data：存放具体的数据

URI：

- 对raw_contacts表添加、删除、更新操作
URI =  content://com.android.contacts/raw_contacts;
- 对data表添加、删除、更新操作：
URI =  content://com.android.contacts/data;
- 根据email对data表查询
URI =content://com.android.contacts/data/emails/filter/*
- 根据电话号码对data表查询
URI =content://com.android.contacts/data/phone/filter/*
- 如果要根据ID查询电话，可以
URI = content://com.android.contacts/data；
然后where条件为：raw_contact_id=? and mimetype = ?



MIMETYPE：
	
- 电话：vnd.android.cursor.item/phone_v2  
- 姓名：vnd.android.cursor.item/name  
- 邮件：vnd.android.cursor.item/email_v2  
- 通信地址：vnd.android.cursor.item/postal-address_v2  
- 组织：vnd.android.cursor.item/organization  
- 照片：vnd.android.cursor.item/photo  

Data中的常量：

- Data._ID： "_id"
- Data.DISPLAY_NAME：“display_name”
- Data.DATA1：“data1”
- Data.DATA2：“data2”
- Data.RAW_CONTACT_ID：“raw_contact_id”
- Data.MIMETYPE：“mimetype”


### ContactProvider和ContentResolver对电话的人员信息的增删改查（ContentResolver02）

activity_main.xml 

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <Button
	        android:id="@+id/showBtn"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:onClick="LoadContact"
	        android:text="显示联系人信息" />
	    <Button
	        android:id="@+id/addBtn"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:onClick="newContact"
	        android:text="新建联系人信息" />
	    <ListView
	        android:id="@+id/lv"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
	</LinearLayout>


item_contact_person.xml：

	<?xml version="1.0" encoding="utf-8"?>
	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:layout_marginBottom="10dp"
	    android:orientation="vertical" >
	    <EditText
	        android:id="@+id/nameId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:padding="5dp"
	        android:textColor="#00f"
	        android:textSize="12sp" />
	    <EditText
	        android:id="@+id/phoneId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:padding="5dp"
	        android:textColor="#000"
	        android:textSize="12sp" />
	    <EditText
	        android:id="@+id/emailId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:padding="5dp"
	        android:textColor="#000"
	        android:textSize="12sp" />
	</LinearLayout>


MainActivity.java：代码有点长

- 查询：LoadContact中通过获取ContentResolver.query查询raw_contacts并且根据其ID查询data表中的具体信息（电话，Email，姓名）
- 修改：创建ContextMenu弹出AlertDialog对话框提示Update或者Add；
	- Add：更行raw_contacts表，返回插入Uri地址，用ContentUris.parseId(Uri contentUri)查询出插入的Uri的ID；根据ID添加data表数据
	- Update：根据点击ListView中Item的ID来获取数据表raw_contacts的主键ID；然后依次更新2张表；
- 删除：弹出菜单栏目中依次根据表的ID删除数据

<nobr/>

	public class MainActivity extends Activity {
		// 访问联系人的信息 ID 和 姓名
		private Uri rawUri = Uri.parse("content://com.android.contacts/raw_contacts");
		private String[] rawColums = { "_id", "display_name" };
	
		// 访问联系人的数据信息 电话号码、邮箱等
		private Uri dataUri = Uri.parse("content://com.android.contacts/data");
		private String[] dataColums = { "data1" };
	
		private ListView lv;
		private List<Map<String,Object>> list;
		private SimpleAdapter adapter;
		
		private AlertDialog editDialog;
		private EditText nameId,phoneId,emailId;
		
		private boolean isAdd=false;	//判断是增加还是编辑
		
		private int currPosition;	//保存当前的Item的位置
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lv=(ListView) findViewById(R.id.lv);
			list=new ArrayList<Map<String,Object>>();
			adapter=new SimpleAdapter(getApplicationContext(), list, R.layout.item_contact_person, 
					new String[]{ "name","phone","email"}, 
					new int[]{R.id.nameId,R.id.phoneId,R.id.emailId});
			lv.setAdapter(adapter);
			
			initDialog();
			
			registerForContextMenu(lv);
		}
	
		@Override
		public void onCreateContextMenu(ContextMenu menu, View v,ContextMenuInfo menuInfo) {
			getMenuInflater().inflate(R.menu.main, menu);
			currPosition=((AdapterContextMenuInfo)menuInfo).position;
			super.onCreateContextMenu(menu, v, menuInfo);
		}
		
		@Override
		public boolean onContextItemSelected(MenuItem item) {
			switch (item.getItemId()) {
			case R.id.action_update:	//添加或者更新
				isAdd=false;
				nameId.setText(String.valueOf(list.get(currPosition).get("name")));
				phoneId.setText(String.valueOf(list.get(currPosition).get("phone")));
				emailId.setText(String.valueOf(list.get(currPosition).get("email")));
				
				editDialog.show();
	
				break;
			case R.id.action_del:	//删除
				getContentResolver().delete(rawUri, "_id="+list.get(currPosition).get("id"), null);
				LoadContact(null);
				break;
			default:
				break;
			}
			return super.onContextItemSelected(item);
		}
		
		private void initDialog() {
			list.clear();
			
			View view=getLayoutInflater().inflate(R.layout.dialog_contact_person, null);
			nameId=(EditText) view.findViewById(R.id.nameId);
			phoneId=(EditText) view.findViewById(R.id.phoneId);
			emailId=(EditText) view.findViewById(R.id.emailId);
			
			editDialog=new AlertDialog.Builder(this)
					.setTitle("设置联系人信息")
					.setIcon(android.R.drawable.ic_menu_add)
					.setView(view)
					.setPositiveButton("确定", new OnClickListener() {
						@Override
						public void onClick(DialogInterface dialog, int which) {
							ContentValues values=new ContentValues();
							String name=nameId.getText().toString();
							String phone=phoneId.getText().toString();
							String email=emailId.getText().toString();
							if(isAdd){
								values.put("display_name",name );
								values.put("display_name_alt", name);
								Uri newUri=getContentResolver().insert(rawUri, values);	//插入到raw_contacts。并且返回新的数据的游标URI地址
								
								//解析新的content_id的值
								long raw_contact_id=ContentUris.parseId(newUri);
								values.clear();
								
								values.put("raw_contact_id",raw_contact_id);
								values.put("data1",name);
								values.put("mimetype","vnd.android.cursor.item/name");
								getContentResolver().insert(dataUri, values);	//插入到raw_contacts。并且返回新的数据的游标URI地址
								
								values.put("data1",phone);
								values.put("mimetype","vnd.android.cursor.item/phone_v2");
								getContentResolver().insert(dataUri, values);
								
								values.put("data1",email);
								values.put("mimetype","vnd.android.cursor.item/email_v2");
								getContentResolver().insert(dataUri, values);
								
							}else{
								//修改联系人信息；
								values.put("display_name",name );
								values.put("display_name_alt", name);
								getContentResolver().update(rawUri, values,
										"_id="+Long.parseLong(list.get(currPosition).get("id").toString()),null);	//插入到raw_contacts。并且返回新的数据的游标URI地址
								values.clear();
								
								//更新联系人姓名
								values.put("data1", name);
								getContentResolver().update(dataUri, values,
										"mimetype_id=7 and raw_contact_id="+Long.parseLong(list.get(currPosition).get("id").toString()),null);	//插入到raw_contacts。并且返回新的数据的游标URI地址
							
							
								//更新联系人电话
								values.put("data1", phone);
								getContentResolver().update(dataUri, values,
										"mimetype_id=5 and raw_contact_id="+Long.parseLong(list.get(currPosition).get("id").toString()),null);	//插入到raw_contacts。并且返回新的数据的游标URI地址
	
								
								//更新联系人邮件
								values.put("data1", email);
								getContentResolver().update(dataUri, values,
										"mimetype_id=1 and raw_contact_id="+Long.parseLong(list.get(currPosition).get("id").toString()),null);	//插入到raw_contacts。并且返回新的数据的游标URI地址
	
							}
							LoadContact(null);
						}
					})
					.setNegativeButton("取消", null)
					.setCancelable(false)
					.create();
		}
		
		public void editContact(View view) {
			isAdd=false;
			editDialog.show();
		}
		
		public void newContact(View view) {
			isAdd=true;
			nameId.setText("");
			phoneId.setText("");
			emailId.setText("");
			editDialog.show();
		}
		
		public void LoadContact(View view) {
			list.clear();
			Cursor cursor = getContentResolver().query(rawUri, rawColums, null, null, null);	//查询所有人员信息
			Map<String,Object> map=null;
			while (cursor.moveToNext()) {
				long id = cursor.getLong(0);
				String name = cursor.getString(1);
				map=new HashMap<String, Object>();
				map.put("id", id);
				map.put("name", name);
				//根据ID和Type到data表中查找phone
				Cursor phoneCursor = getContentResolver().query(dataUri,
						dataColums, "mimetype_id=5 and raw_contact_id=" + id, null,
						null);
				if (phoneCursor.moveToNext()) {
					String phone = phoneCursor.getString(0);
					map.put("phone", phone);
				}
				//根据ID和Type到data表中查找email
				Cursor emailCursor = getContentResolver().query(dataUri,
						dataColums, "mimetype_id=1 and raw_contact_id=" + id, null,
						null);
				if (emailCursor.moveToNext()) {
					String email = emailCursor.getString(0);
					map.put("email", email);
				}
				list.add(map);
			}
			adapter.notifyDataSetChanged();
		}
	}

最后需要添加上读写联系人信息的权限

	<uses-permission android:name="android.permission.READ_CONTACTS"/>
	<uses-permission android:name="android.permission.WRITE_CONTACTS"/>

![android_provider03.png]({{site.baseurl}}/public/img/android_provider03.png)


