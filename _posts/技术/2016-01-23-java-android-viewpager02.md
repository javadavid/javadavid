---
layout: post
title:  "Android ViewPager 应用"
date: 2016/1/23 7:17:43 
categories:
- 技术
tags:
- Android
---

### 实例一：
实现左右移动ViewPager滑块，自动更换标题HorizontalScrollView列表实现；

初始化总布局文件activity_main.xml，实现顶部和底部的控件布局；

- android:scrollbars="none" ：将水平的滚动条设置为无；

<nobr/>

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:orientation="vertical"
	    tools:context=".MainActivity" >
	
	    <HorizontalScrollView
	        android:layout_marginBottom="2dp"
	        android:id="@+id/hScrollViewId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:scrollbars="none" >
	
	        <LinearLayout
	            android:id="@+id/linearLayoutId1"
	            android:layout_width="wrap_content"
	            android:layout_height="wrap_content"
	            android:paddingTop="20dp"
	            android:orientation="vertical" >
	
	            <LinearLayout
	                android:id="@+id/linearLayoutId2"
	                android:layout_width="wrap_content"
	                android:layout_height="wrap_content"
	                android:orientation="horizontal" >
	                <TextView
	                    android:id="@+id/titleId01"
	                    android:layout_width="150dp"
	                    android:layout_height="wrap_content"
	                    android:gravity="center"
	                    android:paddingLeft="10dp"
	                    android:paddingRight="10dp"
	                    android:text="第一页面"
	                    android:textSize="20sp" />
	                <TextView
	                    android:id="@+id/titleId02"
	                    android:layout_width="150dp"
	                    android:layout_height="wrap_content"
	                    android:gravity="center"
	                    android:paddingLeft="10dp"
	                    android:paddingRight="10dp"
	                    android:text="第二页面"
	                    android:textSize="20sp" />
	                <TextView
	                    android:id="@+id/titleId03"
	                    android:layout_width="150dp"
	                    android:layout_height="wrap_content"
	                    android:gravity="center"
	                    android:paddingLeft="10dp"
	                    android:paddingRight="10dp"
	                    android:text="第三页面"
	                    android:textSize="20sp" />
	            </LinearLayout>
	            <View 
	                android:id="@+id/markingView"
	                android:background="#0ac"
	                android:layout_width="150dp"
	                android:layout_height="1dp"/>
	        </LinearLayout>
	    </HorizontalScrollView>
	    
	    <android.support.v4.view.ViewPager
	        android:id="@+id/viewPagerId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
	</LinearLayout>

ViewPager子布局pager_view01.xml  3 个

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity"
	    android:background="#C00" >
	    <TextView
	        android:id="@+id/tvId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:background="#FFc"
	        android:textSize="30sp"
	        android:layout_centerInParent="true"
	        android:text="第一个页面" />
	</RelativeLayout>

MainActivity.java：
说明：

- ViewPager设置子控件
	- 通过getIdentifier(String name, String defType, String defPackage)：取得Layout文件夹中的xml文件ID
	- 通过LayoutInflater查找对应的ID的资源，进行添加
- 设置滚动条的水平平移距离onPageScrolled
	- 当viewPager发生onPageScrolled事件时，将滚动条平移(offset（偏移百分比）+position（偏移位置）)* 滚动条控件的宽
	- 并通过layoutParams设置其距离参数；
- HorizontalScrollView控件移动后居中
	- 当viewPager发生onPageSelected事件时
	- 取得屏幕的资源属性getDisplayMetrics()
	- HScrollView偏移距离left + moduleView.getWidth()/2 - screenWidth/2
	- smoothScrollTo(int x,int y)：动画滑动偏移
- HorizontalScrollView点击后ViewPager移动
	- 初始化给Hscroll的绑定点击事件
	- 绑定点击Item的position到Tag。通过setCurrentItem设置ViewPager的移动；

<nobr/>

	public class MainActivity extends Activity {
		private ViewPager viewPager;
		private List<View> views;
		private PagerAdapter adapter;
		
		private HorizontalScrollView hScrollView;
		private LinearLayout linearLayoutId2;
		private View markingView;
		private LayoutParams paramsMarking;
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			viewPager=(ViewPager) findViewById(R.id.viewPagerId);
			markingView=findViewById(R.id.markingView);
			linearLayoutId2=(LinearLayout) findViewById(R.id.linearLayoutId2);
			hScrollView=(HorizontalScrollView) findViewById(R.id.hScrollViewId);
			paramsMarking=(LayoutParams) markingView.getLayoutParams();
	
			//设置ViewPager的事件方法；
			viewPager.setOnPageChangeListener(new OnPageChangeListener() {
				@Override
				public void onPageSelected(int position) {
					//取得子控件 控件设置标题
					RelativeLayout reLayout = (RelativeLayout) views.get(position);
					TextView tv=(TextView) reLayout.getChildAt(0);
					setTitle(tv.getText());
					
					//将HScrollView滚动到中间，并且设置其子控件属性
					selectModule(position);
				}
	
				@Override
				public void onPageScrolled(int position, float offset, int offsetPixels) {
					//计算滚动条距离右边的margin值	(offset（偏移百分比）+position（偏移位置）)* 滚动条控件的宽
					paramsMarking.leftMargin = (int) (paramsMarking.width*(position+offset));
					markingView.setLayoutParams(paramsMarking);
				}
				
				@Override
				public void onPageScrollStateChanged(int arg0) {
				}
			});
			
			//创建适配器
			adapter=new MyPagerAdapter();
		
			//初始化资源列表
			initViewAdapter();
			
			//设置适配器
			viewPager.setAdapter(adapter);
			
			//将ViewPager子控件 保存在内存中 的限制；
			viewPager.setOffscreenPageLimit(views.size());
	
			//添加HScrollView中TextView点击事件
			ItemClick();
		}
	
	
		private void initViewAdapter() {
			views=new ArrayList<View>();
			for(int i=1;i<=3;i++){
				//取得资源文件的Id
				int layoutResId=getResources().getIdentifier("pager_view0"+i, "layout", getPackageName());
				
				//将资源文件ID添加到views中；
				views.add(getLayoutInflater().inflate(layoutResId, null));
			}
		}
		
		private void ItemClick() {
			View tv=null;
			for(int i=0;i<linearLayoutId2.getChildCount();i++){
				tv= linearLayoutId2.getChildAt(i);
				tv.setTag(i);
				tv.setOnClickListener(new View.OnClickListener() {
					@Override
					public void onClick(View v) {
						int position=(Integer) v.getTag();
						viewPager.setCurrentItem(position);
					}
				});
			}
		}
		
		private void selectModule(int position) {
			TextView moduleView= null;
			for(int i=0;i<linearLayoutId2.getChildCount();i++){
				moduleView=(TextView) linearLayoutId2.getChildAt(i);
				if(i==position){
					moduleView.setTextColor(Color.BLUE);
				}else{
					moduleView.setTextColor(Color.BLACK);
				}
			}
			moduleView=(TextView) linearLayoutId2.getChildAt(position);
			//获取指定位置的模块控件的位置
			int left = moduleView.getLeft();
			//取得屏幕宽度；
			int screenWidth = getResources().getDisplayMetrics().widthPixels;
			
			int offset = left + moduleView.getWidth()/2 - screenWidth/2;
			
			//移动scroll控件位置
			hScrollView.smoothScrollTo(offset, 0);
		}
		
		class MyPagerAdapter extends PagerAdapter{
	
			@Override
			public int getCount() {
				return views.size();
			}
	
			@Override
			public boolean isViewFromObject(View arg0, Object arg1) {
				Log.i("info", " -- isViewFromObject -- ");
				return arg0==arg1;
			}
			
			@Override
			public void destroyItem(ViewGroup container, int position, Object object) {
				Log.i("info", " -- destroyItem -- ");
				container.removeView(views.get(position));
			}
			
			@Override
			public Object instantiateItem(ViewGroup container, int position) {
				Log.i("info", " -- instantiateItem -- ");
				container.addView(views.get(position));
				return views.get(position);
			}
		}
	}

![android_viewpager03.png]({{site.baseurl}}/public/img/android_viewpager03.png)

### 实例二：
通过ListFragment实现ViewPager数据的填充，对support中包的各个控件使用；

ContentFragment：继承support包中的 ListFragment，实现onCreate、onCreateView、onDestroyView、onDestroy：Fragment控件和FragmentItem的创建和销毁的方法；onCreate负责初始化数据源，onActivityCreated负责将数据源设置到adapter中；

	public class ContentFragment extends ListFragment{
		private String title;
		private List<String> datas;
		private ArrayAdapter<String> adapter;
		
		public static ContentFragment newInstance(String title){
			ContentFragment cf=new ContentFragment();
			Bundle args = new Bundle();
			args.putString("title", title);
			cf.setArguments(args);
			return cf;
		}
		
		//创建ListFragment
		@Override
		public void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			Log.i("info", "-- onCreate --");
			title = getArguments().getString("title");
			datas=new ArrayList<String>();
			for(int i=0;i<20;i++){
				datas.add(title + " -- " + i);
			}
			adapter=new ArrayAdapter<String>(getActivity(),R.layout.item,datas);
		}
		
		
		@Override
		public void onActivityCreated(Bundle savedInstanceState) {
			super.onActivityCreated(savedInstanceState);
			setListAdapter(adapter);
		}
	
	
		//ListItem单击事件；方法继承ContentFragment
		@Override
		public void onListItemClick(ListView l, View v, int position, long id) {
			Toast.makeText(getActivity(),"-->" + datas.get(position), 0).show();
		}
		
		//ListFragment中的子控件创建
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container,
				Bundle savedInstanceState) {
			Log.i("info", "-- onCreateView --");
			return super.onCreateView(inflater, container, savedInstanceState);
		}
		
		//ListFragment中的子控件销毁
		@Override
		public void onDestroyView() {
			Log.i("info", "-- onDestroyView --");
			super.onDestroyView();
		}
		
		//ListFragment销毁
		@Override
		public void onDestroy() {
			Log.i("info", "-- onDestroy --");
			super.onDestroy();
		}
	}

item.xml 占位符 和 activity_main.xml主布局：

	<TextView xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    android:textSize="20sp"
	    android:layout_margin="10dp"
	    tools:context=".MainActivity" />

<nobr/>

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <android.support.v4.view.ViewPager
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:id="@+id/viewPagerId"/>
	</RelativeLayout>


MainActivity.java：继承FragmentActivity，因为要使用FragmentActivity.getSupportFragmentManager()取得的是support包中的fragment；

MyPagerAdapter适配器继承support包中的FragmentPagerAdapter：必须覆写其中的构造MyPagerAdapter(FragmentManager fm)和getItem(int position)方法、getCount()方法；

	public class MainActivity extends FragmentActivity{
		
		private ViewPager viewPager;
		private List<Fragment> fragments;
		private FragmentPagerAdapter adapter;
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			
			viewPager=(ViewPager) findViewById(R.id.viewPagerId);
			
			//初始化数据
			initFragment();
		}
	
		private void initFragment() {
			fragments=new ArrayList<Fragment>();
			fragments.add(ContentFragment.newInstance("A"));
			fragments.add(ContentFragment.newInstance("B"));
			fragments.add(ContentFragment.newInstance("C"));
			fragments.add(ContentFragment.newInstance("D"));
			fragments.add(ContentFragment.newInstance("E"));
			
			adapter=new MyPagerAdapter(getSupportFragmentManager());
			
			viewPager.setAdapter(adapter);
		}
	
		class MyPagerAdapter extends FragmentPagerAdapter{
	
			//FragmentPagerAdapter必须要实现的一个构造方法；
			public MyPagerAdapter(FragmentManager fm) {
				super(fm);
			}
	
			@Override
			public Fragment getItem(int position) {
				return fragments.get(position);
			}
	
			@Override
			public int getCount() {
				return fragments.size();
			}
		}
	}


![android_viewpager04.png]({{site.baseurl}}/public/img/android_viewpager04.png)

下面看下其中ListFragment控件在其中的生命周期

![android_viewpager05.png]({{site.baseurl}}/public/img/android_viewpager05.png)

在移动viewPager的过程中，listFragment中始终保存了ListItem的状态信息；从运行来看在移动过程中看，listFragment只创建一次就不会销毁，而只是其中的Item在创建和销毁，销毁只在task结束或者返回时执行；