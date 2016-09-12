---
layout: post
title:  "Android Loader 学习记录"
date: 2016/1/6 15:25:47 
categories:
- 技术
tags:
- Android
---

这一章其实应该在ActionBar前面一章的；嘛不过无所谓了。

### Loader
自动的异步加载数据的作用；

- 支持Activity和Fragment 
	- 继承接口 LoaderCallbacks LoaderManager.initLoader(int id, Bundle args, LoaderCallbacks<Cursor> callback)：参数依次是loader的ID，传入的参数和回调接口
- 能实现异步下载
- 当数据源改变时能及时通知客户端 
- 发生configuration change时自动重连接 

activity_main.xml：布局文件

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <!-- SearchView搜索框 iconifiedByDefault设置当前组建是否是按照图标化显示 -->
	    <SearchView
	        android:id="@+id/searchViewId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" 
	        android:iconifiedByDefault="true"/>
	    <ListView
	        android:id="@+id/lvId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
	</LinearLayout>

创建Loader：ContactLoader.java 继承AsyncTaskLoader<Cursor>方法；

- 需要重写构造方法和loadInBackground方法；
- onStartLoading()当Loader启动时候强制初始化onForceLoad()方法；或者在initLoader后面调用；
- loadInBackground()：是子线程执行的方法；后台线程执行数据源的加载

<nobr/>

	public class ContactLoader extends AsyncTaskLoader<Cursor> {
		private Bundle args;
		
		public ContactLoader(Context context,Bundle args) {
			super(context);
			this.args=args;
		}
		
		@Override
		protected void onStartLoading() {
			super.onStartLoading();
			onForceLoad();	//在开始时候前置执行载入Loader并且回调
		}
		
		@Override
		//查询联系人的姓名和电话
		public Cursor loadInBackground() {
			String where=null;
			String whereArgs[]=null;
			if(args!=null){
				where="display_name like ? or data1 like ? ";
				whereArgs=new String[]{"%"+args.getString("key")+"%","%"+args.getString("key")+"%"};
			}
			return getContext().getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
					new String[]{"_id","display_name","data1"}, 
					where, whereArgs, null);
		}
	}


MainActivity.java实现接口LoaderCallbacks 进行方法回调

- onCreateLoader(int id, Bundle args)：创建Loader，载入的Loader ID和参数
- onLoadFinished(Loader<Cursor> loader, Cursor data)：调用完Loader的实现
- onLoaderReset(Loader<Cursor> loader)：重置Loader
- searchView实现其文本发生改变的监听接口setOnQueryTextListener
	- 当文字或者点击按钮提交的事件；

<nobr/>

	public class MainActivity extends Activity implements LoaderCallbacks<Cursor>{
		private SearchView searchView;
		private ListView lv;
		private SimpleCursorAdapter adapter;
	
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lv=(ListView) findViewById(R.id.lvId);
			searchView=(SearchView) findViewById(R.id.searchViewId);	//searchView搜索框
	
			adapter=new SimpleCursorAdapter(getApplicationContext(),R.layout.item_contact_phone,null,
					new String[]{"display_name","data1"},new int[]{R.id.nameId,R.id.phoneId},
					SimpleCursorAdapter.FLAG_REGISTER_CONTENT_OBSERVER);
			lv.setAdapter(adapter);
	
			searchView.setOnQueryTextListener(new OnQueryTextListener() {
				@Override
				public boolean onQueryTextSubmit(String query) {
					// 按搜索键提交事件
					return false;
				}
				@Override
				public boolean onQueryTextChange(String newText) {
					Bundle args=new Bundle();
					args.putString("key", newText);
					getLoaderManager().restartLoader(0, args, MainActivity.this);	//重新载入Loader
					return false;
				}
			});
			getLoaderManager().initLoader(0, null, this);	//初始化Loader
		}
	
		@Override
		public Loader<Cursor> onCreateLoader(int id, Bundle args) {
			// 创建调用返回Loader加载器
			return new ContactLoader(getApplicationContext(),args);
		}
	
		@Override
		public void onLoadFinished(Loader<Cursor> loader, Cursor data) {
			adapter.swapCursor(data);	//调用完成自动载入adapter数据
		}
	
		@Override
		public void onLoaderReset(Loader<Cursor> loader) {
			adapter.swapCursor(null);
		}
	}

![android_loader01.png]({{site.baseurl}}/public/img/android_loader01.png)

