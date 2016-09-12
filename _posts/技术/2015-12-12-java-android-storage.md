---
layout: post
title:  "Android Storage 学习记录"
date: 2015/12/12 16:09:00 
categories:
- 技术
tags:
- Android
---

## Storage的分类
 
- Shared Preferences：共享存储，原始的键值对；
- Internal Storage：内部存储
- External Storage：扩展存储
- SQLite Databases：数据库
- Network Connection：网络


### Shared Preferences
- 写操作：通过 getSharedPreferences(String name,int mode)传入引用的名称和存储的类型，返回SharedPreferences对象；通过接口SharedPreferences.Editor的put方法设置值提交

		public void write(View view){
			SharedPreferences sf= getSharedPreferences("set", Context.MODE_PRIVATE);
			SharedPreferences.Editor edit=sf.edit();
			edit.putInt("color", Color.RED);
			edit.putInt("backGroundColor", Color.BLACK);
			edit.putBoolean("allCaps", true);
			edit.commit();
			Toast.makeText(getApplicationContext(), "write ok", 1).show();
		}

	- 此时点击后会在项目目录生成文件 包路径/shared_prefs/set.xml;文件内容如下
![android_storage01.png]({{site.baseurl}}/public/img/android_storage01.png)
		 

- 读操作：直接通过取得SharedPreferences，直接使用get读取相应数据

		public void read(View view){
			SharedPreferences sf= getSharedPreferences("set", Context.MODE_PRIVATE);
			tv.setTextColor(sf.getInt("color", Color.RED));
			tv.setBackgroundColor(sf.getInt("backGroundColor", Color.BLACK));
			tv.setAllCaps(sf.getBoolean("allCaps", true));
			Toast.makeText(getApplicationContext(), "read ok", 1).show();
		}

	![android_storage02.png]({{site.baseurl}}/public/img/android_storage02.png)


#### Shared Preferences应用（延伸 Storage01）

MainActivity：设置文字的属性后，按退出后重启依然保存内容

- 将TextView的各种变量保存在全局中
- onCreate初始取得TextView并读取共享存储
- onDestroy保存在共享存储中
- 通过判断item.getItemId()来执行创建的ContextMenu的动作

<nobr/>

	public class MainActivity extends Activity {
		private TextView tv;
		private int changeBackgroundColor;
		private int changeFontColor;
		private float addfontSize;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			tv = (TextView) findViewById(R.id.tvId);
			registerForContextMenu(tv);
			read(null);
		}
	
		@Override
		public void onCreateContextMenu(ContextMenu menu, View v,
				ContextMenuInfo menuInfo) {
			getMenuInflater().inflate(R.menu.main, menu);
			super.onCreateContextMenu(menu, v, menuInfo);
		}
	
		@Override
		public boolean onContextItemSelected(MenuItem item) {
			switch (item.getItemId()) {
				case R.id.changeBackgroundColor:
					changeBackgroundColor=Color.rgb((int)(Math.random()*256),(int)(Math.random()*256), (int)(Math.random()*256));
					tv.setBackgroundColor(changeBackgroundColor);
					break;
				case R.id.changeFontColor:
					changeFontColor=Color.rgb((int)(Math.random()*256),(int)(Math.random()*256), (int)(Math.random()*256));
					tv.setTextColor(changeFontColor);
					break;
				case R.id.addfontSize:
					addfontSize+=tv.getTextSize()+10;
					tv.setTextSize(addfontSize);
					break;
				default:
					break;
			} 
			return super.onContextItemSelected(item);
		}
	
		public void read(View view) {
			SharedPreferences sf = getSharedPreferences("set", Context.MODE_PRIVATE);
			tv.setTextColor(sf.getInt("textColor", tv.getCurrentTextColor()));
			tv.setBackgroundColor(sf.getInt("backGroundColor", ((ColorDrawable)tv.getBackground()).getColor()));
			tv.setTextSize(sf.getFloat("textSize" , tv.getTextSize()));
			tv.setAllCaps(sf.getBoolean("allCaps", true));
			Toast.makeText(getApplicationContext(), "read ok", 1).show();
		}
	
		public void write(View view) {
			SharedPreferences sf = getSharedPreferences("set", Context.MODE_PRIVATE);
			SharedPreferences.Editor edit = sf.edit();
			edit.putInt("textColor", changeFontColor);
			edit.putInt("backGroundColor",changeBackgroundColor);
			edit.putFloat("textSize",addfontSize);
			edit.putBoolean("allCaps", true);
			edit.commit();
			Toast.makeText(getApplicationContext(), "write ok", 1).show();
		}
		
		@Override
		protected void onDestroy() {
			write(null);
			super.onDestroy();
		}
	}

![android_storage03.png]({{site.baseurl}}/public/img/android_storage03.png)


### Internal Storage

- 通过openFileOutput(String name, int mode)打开输出流，保存文件
- 通过openFileInput(String name)打开输入流，读取文件
- 文件保存内容在 包名称/files/文件名;


布局文件：activity_main.xml：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <LinearLayout
	        android:orientation="horizontal"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" >
	        <EditText
	            android:id="@+id/nameId"
	            android:layout_weight="1"
	            android:singleLine="true"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:hint="请输入文件名"/>
	        <Button
	            android:onClick="openFile"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:text="打开" />
	        <Button
	            android:onClick="saveFile"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:text="保存" />
	    </LinearLayout>
	    <EditText
	        android:id="@+id/contentId"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"
	        android:hint="文件内容"/>
	</LinearLayout>

MainActivity.java：
	
	public class MainActivity extends Activity {
		EditText nameId,contentId;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			contentId=(EditText) findViewById(R.id.contentId);
			nameId=(EditText) findViewById(R.id.nameId);
		}
	
		public void openFile(View view) {
			String fileName=nameId.getText().toString().trim();	//文件名
			try {
				FileInputStream fis= openFileInput(fileName);
				byte[] b=new byte[fis.available()];
				fis.read(b);
				fis.close();
				contentId.setText(new String(b));
				Toast.makeText(getApplicationContext(), "open success", 0).show();
			} catch ( Exception e) {
				e.printStackTrace();
			}
		}
	
		public void saveFile(View view) {
			String fileName=nameId.getText().toString().trim();	//文件名
			String content=contentId.getText().toString().trim();//文件内容
			try {
				FileOutputStream fos=openFileOutput(fileName, Context.MODE_PRIVATE);
				fos.write(content.getBytes());
				fos.close();
				Toast.makeText(getApplicationContext(), "save success", 0).show();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

![android_storage04.png]({{site.baseurl}}/public/img/android_storage04.png)

#### Internal Storage应用（延伸 Storage02）

添加Options菜单，选择后显示AlertDialog对话框，选择打开相应文件

- 启动初始化控件和adapter布局文件，设置监听
- 通过fileList()返回其中的私有模式的文件列表，并且放入到adapter中
- 点击列表重置nameId的Text属性，读取显示文件内容

MainActivity.java：

	public class MainActivity extends Activity {
		private EditText nameId,contentId;
		private AlertDialog dialog;
		private ArrayAdapter<String> adapter;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			contentId=(EditText) findViewById(R.id.contentId);
			nameId=(EditText) findViewById(R.id.nameId);
			
			adapter=new ArrayAdapter<String>(this, R.layout.item);
			dialog=new AlertDialog.Builder(this)
					.setTitle("请选择文件")
					.setIcon(android.R.drawable.ic_dialog_alert)
					.setAdapter(adapter, new DialogInterface.OnClickListener() {
						@Override
						public void onClick(DialogInterface dialog, int which) {
							nameId.setText(adapter.getItem(which));
							openFile(null);
						}
					})
					.create();
		}
	
		@Override
		public boolean onCreateOptionsMenu(Menu menu) {
			getMenuInflater().inflate(R.menu.main, menu);
			return super.onCreateOptionsMenu(menu);
		}
		
		@Override
		public boolean onOptionsItemSelected(MenuItem item) {
			if(item.getItemId()==R.id.selectId){
				adapter.clear();
				adapter.addAll(fileList());
				dialog.show();
			}
			return super.onOptionsItemSelected(item);
		}
		
		public void openFile(View view) {
			String fileName=nameId.getText().toString().trim();	//文件名
			try {
				FileInputStream fis= openFileInput(fileName);
				byte[] b=new byte[fis.available()];
				fis.read(b);
				fis.close();
				contentId.setText(new String(b));
				Toast.makeText(getApplicationContext(), "open success", 0).show();
			} catch ( Exception e) {
				e.printStackTrace();
			}
		}
	
		public void saveFile(View view) {
			String fileName=nameId.getText().toString().trim();	//文件名
			String content=contentId.getText().toString().trim();//文件内容
			try {
				FileOutputStream fos=openFileOutput(fileName, Context.MODE_PRIVATE);
				fos.write(content.getBytes());
				fos.close();
				Toast.makeText(getApplicationContext(), "save success", 0).show();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}


![android_storage05.png]({{site.baseurl}}/public/img/android_storage05.png)

### External Storage（扩展存储）
目录`"/mnt/sdcard"` 

![android_storage07.png]({{site.baseurl}}/public/img/android_storage07.png)

分别对应 **Environment** 下面的各种常量名称;

- Environment.getDataDirectory():取扩展卡的文件根路径
- Environment.getExternalStorageState():取得扩展卡当前状态
- Bitmap.compress(CompressFormat format, int quality, OutputStream stream):将图片压缩的方法;
- BitmapFactory.decodeFile(String pathName):转换文件为BitMap类型;

<nobr/>

	public class FileUtils {
		// 保存图片的缓存路径
		public static final String CACHE_DIR = Environment.getDataDirectory() + "/Storage03/imgcache/";
	
		public static final int FORMAT_JPEG=1;
		public static final int FORMAT_PNG=2;
		
		public static boolean isMounted() {
			//返回扩展卡是否挂载
			return Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);
		}
	
		//保存为字节流图片
		public static void saveImage(String url, byte[] bytes) throws IOException {
			if(!isMounted()) return ;
			File dir=new File(CACHE_DIR);
			if(!dir.isDirectory()) dir.mkdirs();	//判断文件路径
			FileOutputStream fos=new FileOutputStream(new File(dir,getFileName(url)));
			fos.write(bytes);
			fos.close();
		}
	
		//保存为Bitmap图片
		public static void saveImage(String url, Bitmap bitmap,int format) throws IOException {
			if(!isMounted()) return ;
			File dir=new File(CACHE_DIR);
			if(!dir.isDirectory()) dir.mkdirs();	//判断文件路径
			FileOutputStream fos=new FileOutputStream(new File(dir,getFileName(url)));
			
			bitmap.compress(format==FORMAT_JPEG?CompressFormat.JPEG:CompressFormat.PNG, 100, fos);		//将输入流转换成BitMap流
		}
		
		public static Bitmap readImage(String url) {
			if(!isMounted()) return null;
			File imageFile=new File(CACHE_DIR,getFileName(url));
			if(imageFile.exists()){
				return BitmapFactory.decodeFile(imageFile.getAbsolutePath());
			}
			return null;
		}
		
		public static String getFileName(String url){
			return url.substring(url.lastIndexOf("/")+1);
		}
	}


### SQLite Databases（Storage04）

创建sqlite的数据库文件默认位置保存在 安装包的database目录下面

- 继承SQLiteOpenHelper方法，并且实现其构造函数，实现数据库文件实例化；
- onCreate：初始化数据库的table文件；
- onUpgrade：当数据库版本更新时候的 执行方法；

DBHelp.java：

	public class DBHelp extends SQLiteOpenHelper {
		public DBHelp(Context context) {
			/**
			 * 第二参数：数据库名称，默认的位置在安装包的database目录下面
			 * 第三参数：CursorFactory 游标工厂。
			 * 第四参数：数据库版本号
			 */
			super(context, "gp06.db", null, 1);	
		}
	
		//初始化数据库；
		@Override
		public void onCreate(SQLiteDatabase db) {
			db.execSQL("create table t_fav(_id integer primary key,id,title,info,web_content,fav_data,model_type)");
			db.execSQL("create table t_person(_id integer primary key,name,age,tel)");
		}
	
		//更新或者升级数据库；
		@Override
		public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
			if(newVersion>oldVersion){
				db.execSQL("drop table if exists t_fav");
				db.execSQL("drop table if exists t_person");
			}
		}
	}

MainActivity.java代码：

- 通过构造SimpleCursorAdapter(Context context, int layout, Cursor c, String[] from, int[] to, int flags)初始化SimpleCursorAdapter类，设置layout中控件对象的对应关系；
- 通过getReadableDatabase()方法，实例化SQLiteDatabase对象；
- 然后通过query查询对象游标
- 设置adapter游标
- 通过ContentValues存储对象值，然后插入值。
- 关闭数据库，载入数据

<nobr/>
	
	public class MainActivity extends Activity {
		private ListView lv;
		private Cursor cursor;
		private DBHelp dbHelper;
		private SimpleCursorAdapter adapter;
		
		private String[] columns=new String[]{"_id","name","age","tel"};
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lv=(ListView) findViewById(R.id.lvId);
			dbHelper=new DBHelp(getApplicationContext());
			adapter=new SimpleCursorAdapter(getApplicationContext(), R.layout.item_user, cursor,
					new String[]{"name","age","tel"} ,
					new int[]{R.id.nameId,R.id.ageId,R.id.telId},
					SimpleCursorAdapter.FLAG_REGISTER_CONTENT_OBSERVER);
			loadData();
			lv.setAdapter(adapter);
		}
		
		private void loadData() {
			SQLiteDatabase sdb=dbHelper.getReadableDatabase();
			
			//查询表
			cursor=sdb.query("t_person", columns, null, null, null, null, null);
			
			//切换数据源；
			adapter.swapCursor(cursor);
		}

		//向数据库添加数据
		public void addPerson(View view){
			SQLiteDatabase sdb=dbHelper.getReadableDatabase();
			ContentValues values=new ContentValues();
			
			values.put("name", "张三");
			values.put("age", (int)(Math.random()*10+20));
			values.put("tel",10086);
			
			long id=sdb.insert("t_person", null, values);
			if(id!=-1){
				Toast.makeText(getApplicationContext(), " --> 数据插入成功 ", 1).show();
			}
			sdb.close();
			
			loadData();
		}
	}

![android_storage06.png]({{site.baseurl}}/public/img/android_storage06.png)









