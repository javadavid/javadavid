---
layout: post
title:  "Android ListView 学习记录 - 列表滚动组件 "
date: 2015/11/19 15:08:02 
categories:
- 技术
tags:
- Android
---


### 继承关系
	java.lang.Object
		android.view.View
		  android.view.ViewGroup
			  android.widget.AdapterView<ListAdapter>
				  android.widget.AbsListView
					  android.widget.ListView

### 监听事件

- setOnScrollListener：监听滚动事件；

- onScrollStateChanged：状态改变触发的事件,实现当滚动改变时触发事件（有ListView程序启动就触发）

- scrollState：当前滚动的状态

		OnScrollListener.SCROLL_STATE_TOUCH_SCROLL：当用户获得焦点滚动时候的状态
		OnScrollListener.SCROLL_STATE_FLING：当滚动停止时候的状态
		OnScrollListener.SCROLL_STATE_FLING：当快速滚动时候的状态

- onScroll：在滚动中触发的事件；

>view：当前的ListView；
>
>firstVisibleItem：程序启动时候的第一个View的ID；
>
>visibleItemCount：可见的View Item个数；
>
>totalItemCount：总共的Item个数；

	lvId.setOnScrollListener(new OnScrollListener() {
		@Override
		public void onScrollStateChanged(AbsListView view, int scrollState){
			switch (scrollState){
				case OnScrollListener.SCROLL_STATE_TOUCH_SCROLL:
					Log.i("info", "- SCROLL_STATE_TOUCH_SCROLL -");
					break;
				case OnScrollListener.SCROLL_STATE_FLING:	
					Log.i("info", "- SCROLL_STATE_FLING -");
					break;
				case OnScrollListener.SCROLL_STATE_IDLE:
					Log.i("info", "- SCROLL_STATE_IDLE -");
					break;
				default:
					break;
			}
		}
		@Override
		public void onScroll(AbsListView view, int firstVisibleItem,int visibleItemCount, int totalItemCount) {
			Log.i("info", "view -"+view.getId()+" - firstVisibleItem:"+firstVisibleItem+
					" - visibleItemCount:"+visibleItemCount+
					" - totalItemCount:"+totalItemCount);
		}
	});

### 状态变化
**程序启动：**首先会执行初始化 执行onScroll()

![android_listview_scroll01]({{site.baseurl}}/public/img/android_listview_scroll01.png)



**程序滚动 到 停止的状态变化：**会调用 onScrollStateChanged() 执行程序的状态变化

	SCROLL_STATE_TOUCH_SCROLL(用户获得焦点滚动) 
	(SCROLL_STATE_FLING:若有快速滑动则有这个状态) 
	SCROLL_STATE_IDLE(停止滚动)

![android_listview_scroll02.PNG]({{site.baseurl}}/public/img/android_listview_scroll02.png)



所以可以通过一下条件判断 ListView 是否滚动到底部并且停止了。一般用于加载数据；

- firstVisibleItem+visibleItemCount==totalItemCount
- OnScrollListener.SCROLL_STATE_FLING

----------

### 修改例子

关于上一节中的新闻列表中添加滚动事件的例子

![android_new03.PNG]({{site.baseurl}}/public/img/android_new03.png)


#### 添加相关的滚动事件

>当数据没有正在加载或滚动到底部，并且处于停止状态时候；

具体的是要给ListView添加滚动事件；对载入数据的事件封装、各种全局变量 设置

	public class MainActivity extends Activity {
		private Spinner cateSpinner;
		private List<FeedCategory> fcdatas; 
		private List<Feed> fdatas; 
	 	private ArrayAdapter<FeedCategory> fcadapter;
	 	private FeedAdapter fadapter;
		private ListView lv;
		private ProgressDialog pd;
		
		private int currPage=1;	//当前页面
		private int cateId;
		private boolean isLoading=false; //标识是否正在加载数据	false：标识不需要加载
		private boolean flag=false; //标识ListView是否到底部
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			pd=new ProgressDialog(this);	//进度条显示 context需要传this对象
			pd.setMessage("Loading...");
			initAndLoadFeedCategoryDatas();
			
			initLoadFeedDatas();
		}
		
		//获取Feed数据
		private void initLoadFeedDatas() {
			lv=(ListView) findViewById(R.id.lvid);
			fdatas=new ArrayList<Feed>();
			fadapter=new FeedAdapter(getApplicationContext(), fdatas);
			lv.setAdapter(fadapter);
			
			//设置滚动事件
			lv.setOnScrollListener(new OnScrollListener() {
				@Override
				public void onScrollStateChanged(AbsListView view, int scrollState) {
					if(flag&&scrollState==OnScrollListener.SCROLL_STATE_IDLE&&!isLoading){
						loadFeedData();
					}
				}
				
				/*
				 * view:代表当前的listView
				 * firstVisibleItem：可见的当前第一个Item
				 * visibleItemCount：可见的 Item 的数量
				 * totalItemCount：listView的Item的总数；
				 */
				@Override
				public void onScroll(AbsListView view, int firstVisibleItem,int visibleItemCount, int totalItemCount) {
					if(firstVisibleItem+visibleItemCount==totalItemCount){
						flag=true;
					}else{
						flag=false;
					}
				}
			});
		}
	
		//获取分类数据
		private void initAndLoadFeedCategoryDatas() {
			cateSpinner=(Spinner) findViewById(R.id.cateSpinnerId);
			fcdatas=new ArrayList<FeedCategory>();
			fcadapter=new ArrayAdapter<FeedCategory>(getApplicationContext(), R.layout.item_cate, fcdatas);
			cateSpinner.setAdapter(fcadapter);
			
			//分类下拉框改变时候，更新feed数据；
			cateSpinner.setOnItemSelectedListener(new OnItemSelectedListener() {
				@Override
				public void onItemSelected(AdapterView<?> parent, View v,int position, long id) {
					fdatas.clear();
					currPage=1;	//重置分类时候，需要重新载入数据
					cateId = fcdatas.get(position).getId();	//动态改变全局的分类
					loadFeedData();
				}
	
				@Override
				public void onNothingSelected(AdapterView<?> parent) {}
			});
			
			
			//通过回调进行设置从网络取得的值
			new CategroyTask(new CategroyTask.CallBack(){
				@Override
				public void response(List<FeedCategory> list) {
					fcdatas.addAll(list);
					fcadapter.notifyDataSetChanged();
				}
			}).execute(Urls.CATEGORY_URL);
		}
	
		private void loadFeedData() {
			isLoading=true;
			pd.show();		//显示滚动条
			String url=String.format(Urls.LIST_URL, cateId,currPage);
			new FeedTask(new FeedTask.CallBack() {
				@Override
				public void response(List<Feed> list) {
					Log.i("info", "load ok,currPage:"+currPage+",cateId:"+cateId);
					fdatas.addAll(list);
					fadapter.notifyDataSetChanged();	
					
					isLoading=false;
					currPage++;
					pd.hide();	//隐藏滚动条
				}
			}).execute(url);
		}
	}


运行如下图：代码项目	ListView_News

![android_new04]({{site.baseurl}}/public/img/android_new04.png)



#### 改变载入进度的显示方式

main布局文件：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	    <Spinner
	        android:id="@+id/cateSpinnerId"
	        android:layout_width="fill_parent"
	        android:layout_height="wrap_content" />
	    <ListView
	        android:id="@+id/lvid"
	        android:layout_width="match_parent"
	        android:layout_height="0dp"
	        android:layout_weight="1"/>
	    <Button
	        android:id="@+id/btnId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:onClick="loadMore"
	        android:text="显示更多"
	        android:visibility="gone" />
	    <LinearLayout
	        android:id="@+id/progLayoutId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:orientation="horizontal"
	        android:visibility="gone">
	        <ProgressBar
	            android:id="@+id/proBarId"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content" />
	        <TextView
	            android:layout_width="match_parent"
	            android:layout_height="match_parent"
	            android:gravity="center"
	            android:text="正在加载数据.." />
	    </LinearLayout>
	</LinearLayout>
	
>android:visibility="gone"：组件隐藏，没有占位空间；
>
>android:gravity="center"：文本居中显示；

加入了ProgressBar 和 载入按钮 Button
		
	public class MainActivity extends Activity {
		private Spinner cateSpinner;
		private List<FeedCategory> fcdatas; 
		private List<Feed> fdatas; 
	 	private ArrayAdapter<FeedCategory> fcadapter;
	 	private FeedAdapter fadapter;
		private ListView lv;
		private ProgressDialog pd;
	
		private Button moreBtn;
		private LinearLayout proLayout;
		
		
		private int currPage=1;	//当前页面
		private int cateId;
		private boolean isLoading=false; //标识是否正在加载数据	false：标识不需要加载
		private boolean flag=false; //标识ListView是否到底部
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			pd=new ProgressDialog(this);	//进度条显示 context需要传this对象
			pd.setMessage("Loading...");
			
			moreBtn=(Button) findViewById(R.id.btnId);
			proLayout=(LinearLayout) findViewById(R.id.progLayoutId);
			
			initAndLoadFeedCategoryDatas();
			
			initLoadFeedDatas();
		}
		
		//获取Feed数据
		private void initLoadFeedDatas() {
			lv=(ListView) findViewById(R.id.lvid);
			fdatas=new ArrayList<Feed>();
			fadapter=new FeedAdapter(getApplicationContext(), fdatas);
			lv.setAdapter(fadapter);
			
			//设置滚动事件
			lv.setOnScrollListener(new OnScrollListener() {
				@Override
				public void onScrollStateChanged(AbsListView view, int scrollState) {
					if(flag&&scrollState==OnScrollListener.SCROLL_STATE_IDLE&&!isLoading){
						//loadFeedData();
						moreBtn.setVisibility(View.VISIBLE);
					}else {
						moreBtn.setVisibility(View.GONE);
					}
				}
				
				/*
				 * view:代表当前的listView
				 * firstVisibleItem：可见的当前第一个Item
				 * visibleItemCount：可见的 Item 的数量
				 * totalItemCount：listView的Item的总数；
				 */
				@Override
				public void onScroll(AbsListView view, int firstVisibleItem,int visibleItemCount, int totalItemCount) {
					if(firstVisibleItem+visibleItemCount==totalItemCount){
						flag=true;
					}else{
						flag=false;
					}
				}
			});
		}
	
		public void loadMore(View view) {
			view.setVisibility(View.GONE);
			loadFeedData();
			
		}
		
		//获取分类数据
		private void initAndLoadFeedCategoryDatas() {
			cateSpinner=(Spinner) findViewById(R.id.cateSpinnerId);
			fcdatas=new ArrayList<FeedCategory>();
			fcadapter=new ArrayAdapter<FeedCategory>(getApplicationContext(), R.layout.item_cate, fcdatas);
			cateSpinner.setAdapter(fcadapter);
			
			//分类下拉框改变时候，更新feed数据；
			cateSpinner.setOnItemSelectedListener(new OnItemSelectedListener() {
				@Override
				public void onItemSelected(AdapterView<?> parent, View v,int position, long id) {
					fdatas.clear();
					moreBtn.setVisibility(View.GONE);
					currPage=1;	//重置分类时候，需要重新载入数据
					cateId = fcdatas.get(position).getId();	//动态改变全局的分类
					loadFeedData();
				}
	
				@Override
				public void onNothingSelected(AdapterView<?> parent) {}
			});
			
			
			//通过回调进行设置从网络取得的值
			new CategroyTask(new CategroyTask.CallBack(){
				@Override
				public void response(List<FeedCategory> list) {
					fcdatas.addAll(list);
					fcadapter.notifyDataSetChanged();
				}
			}).execute(Urls.CATEGORY_URL);
		}
	
		private void loadFeedData() {
			isLoading=true;
			//pd.show();		//显示滚动条
			proLayout.setVisibility(View.VISIBLE);
			String url=String.format(Urls.LIST_URL, cateId,currPage);
			new FeedTask(new FeedTask.CallBack() {
				@Override
				public void response(List<Feed> list) {
					Log.i("info", "load ok,currPage:"+currPage+",cateId:"+cateId);
					fdatas.addAll(list);
					fadapter.notifyDataSetChanged();
					
					isLoading=false;
					currPage++;
					//pd.hide();	//隐藏滚动条
					proLayout.setVisibility(View.GONE);
				}
			}).execute(url);
		}
	}

效果截图：
![android_new05.PNG]({{site.baseurl}}/public/img/android_new05.png)
 