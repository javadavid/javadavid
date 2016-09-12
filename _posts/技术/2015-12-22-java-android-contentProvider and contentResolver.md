---
layout: post
title:  "Android ContentProvider和ContentResolver 学习记录"
date: 2015/12/22 13:07:19 
categories:
- 技术
tags:
- Android
---

### ContentProvider（ContentProvider02）

作用提供存储数据（storage）的对外接口，以便于统一格式实现数据共享和读取；


这里使用的数据库共享

首先实现数据库的创建类：DBHelper(继承SQLiteOpenHelper，创建数据库相关表)

	public class DBHelper extends SQLiteOpenHelper {
		public DBHelper(Context context) {
			super(context, "users.db", null,1);
		}
	
		@Override
		public void onCreate(SQLiteDatabase db) {
			db.execSQL("create table t_user(_id integer primary key,uname,upass,money)");
			db.execSQL("create table t_order(_id integer primary key,product_name,price,user_id)");
			
			db.execSQL("insert into t_user(uname,upass,money) values('zhangsan','123','1234') ");
			db.execSQL("insert into t_user(uname,upass,money) values('zhangsan2','1232','12342') ");
		}
	
		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			if(newVersion > oldVersion){
				db.execSQL("drop table t_user if exists");
				db.execSQL("drop table t_order if exists");
				onCreate(db);
			}
		}
	}


继承类ContentProvider，可以覆写以下的数据库操作方法。

- onCreate()
- delete(Uri, String, String[])
- getType(Uri)
- insert(Uri, ContentValues)
- query(Uri, String[], String, String[], String)
- update(Uri, ContentValues, String, String[])

使用UriMatcher类加入URI地址，创建uri地址（相当于对外的数据接口地址的）

这里覆写onCreate和query方法

	public static final String AUTHORITY="com.example.contentprovider02";
	
	//标识数据库表
	public static final int CODE_USER=0;
	public static final int CODE_ORDER=1;
	
	//uri资源匹配器
	private static UriMatcher uriMatch;
	static{
		//content://com.example.contentprovider02/users
		uriMatch=new UriMatcher(UriMatcher.NO_MATCH);
		uriMatch.addURI(AUTHORITY, "users", CODE_USER);
		uriMatch.addURI(AUTHORITY, "orders", CODE_ORDER);
	}
	
	private DBHelper dbhelper;

	@Override
	public boolean onCreate() {
		dbhelper=new DBHelper(getContext());
		return false;
	}

	@Override
	public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs,String sortOrder) {
		//获取数据库连接
		SQLiteDatabase sdb=dbhelper.getReadableDatabase();
		Cursor cursor=null;
		
		switch (uriMatch.match(uri)) {
		case CODE_USER:
			cursor=sdb.query("t_user", projection, selection, selectionArgs, null,null,sortOrder);
			break;

		default:
			break;
		}
		return cursor;
	}

AndroidManifest.xml配置：配置相关的标识、权限等。

	<!-- 
    	注册contentProvider 
    	android:authorities：标识当前组件的唯一标识  
    	android:permission:配置访问权限标识
    	android:exported="true":可以被外部应用访问
	-->
    <provider android:name="com.example.contentprovider.UserContentProvider" 
        android:authorities="com.example.contentprovider02"
        android:permission="com.example.contentprovider02.user.WRITE_READ"
        android:exported="true"/>


### ContentResolver（ContentResolver01_02）

对外接口的访问的实现类：使用getContentResolver实例化ContentResolver，然后查询得到游标，循环出数据列表；

	public class MainActivity extends Activity {
		private ListView lvId;
		private List<String> data;
		private ArrayAdapter<String> adapter;
		
		private Uri uri=Uri.parse("content://com.example.contentprovider02/users");
		private String[] colums={"_id","uname","upass","money"};
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lvId=(ListView) findViewById(R.id.lvId);
			data=new ArrayList<String>();
			adapter=new ArrayAdapter<String>(getApplicationContext(), R.layout.item_user,data);
			lvId.setAdapter(adapter);
			loadDate();
		}
	
		private void loadDate() {
			Cursor cursor=getContentResolver().query(uri, colums, null, null, null);
			while(cursor.moveToNext()){
				long id=cursor.getLong(0);
				String uname=cursor.getString(1);
				String upass=cursor.getString(2);
				int money=cursor.getInt(3);
				data.add("id:"+id+",uname:"+uname +",upass:"+ upass +",money:"+ money);
			}
			cursor.close();
			adapter.notifyDataSetChanged();
		}
	}

![android_provider01.png]({{site.baseurl}}/public/img/android_provider01.png)




