---
layout: post
title:  "Android ViewPager 学习记录"
date: 2016/1/22 12:51:39  
categories:
- 技术
tags:
- Android
---



## ViewPager
用来显示界面子控件的页面的切换效果。是android support扩展包中的一个空间，他的控件适配器为PagerAdapter

看代码演示；

布局文件activity_main.xml

	<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <android.support.v4.view.ViewPager
	        android:id="@+id/viewpager"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content" />
	    <LinearLayout
	        android:id="@+id/navLayoutId"
	        android:layout_width="match_parent"
	        android:layout_height="wrap_content"
	        android:layout_gravity="bottom"
	        android:layout_marginBottom="50dp"
	        android:gravity="center"
	        android:orientation="horizontal" />
	</FrameLayout>

MainActivity.java：相应的方法注释中也有说明；

- MyPagerAdapter继承PagerAdapter；实现以下四个方法
	- getCount()：返回当前窗体的界面数
	- isViewFromObject()：判断对象是否是由界面生成
	- instantiateItem()：返回当前适配器选择的Item，初始化作用
	- destroyItem()：销毁当前的View
- pager.setCurrentItem(int position)：设置当前的ViewPager显示的相应位置子控件
- pager.setOnPageChangeListener(OnPageChangeListener l)：ViewPager滑动时候的事件效果
	- onPageSelected(int position)：选择指定页面事件
	- onPageScrolled(int position, float offset, int offsetpix)：滑动中的处理方法
	- onPageScrollStateChanged(int state)：滚动状态的改变事件
		- SCROLL_STATE_DRAGGING：开始
		- SCROLL_STATE_IDLE：停止
		- SCROLL_STATE_SETTLING：滚动中

<nobr/>

	public class MainActivity extends Activity {
		private ViewPager pager = null;
		private PagerAdapter adapter;
		private List<ImageView> views;
		private LinearLayout navLayout;
		private LinearLayout.LayoutParams params;
	
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			// 实例化控件
			pager = (ViewPager) findViewById(R.id.viewpager);
			navLayout = (LinearLayout) findViewById(R.id.navLayoutId);
	
			// 添加view对象
			views = new ArrayList<ImageView>();
			for (int i = 0; i < 3; i++) {
				ImageView img = new ImageView(getApplicationContext());
				img.setTag(i);
				img.setImageResource(R.drawable.logo_vip);
				img.setScaleType(ScaleType.CENTER);
				img.setOnClickListener(new OnClickListener() {
					@Override
					public void onClick(View v) {
						Toast.makeText(getApplicationContext(),"点击图片TagId = " + v.getTag(), 0).show();
					}
				});
				views.add(img);
	
				// 导航图片
				ImageView navimg = new ImageView(getApplicationContext());
				if (i == 0) {
					navimg.setImageResource(R.drawable.icon_choose_dot_s);
				} else {
					navimg.setImageResource(R.drawable.icon_choose_dot_n_1);
				}
				params = new LayoutParams(LayoutParams.WRAP_CONTENT,LayoutParams.WRAP_CONTENT);
				params.leftMargin = 10;
				params.rightMargin = 10;
				navimg.setLayoutParams(params);
	
				navLayout.addView(navimg);
			}
			// 适配adapter
			adapter = new MyPagerAdapter();
			pager.setAdapter(adapter);
	
			pager.setOnPageChangeListener(new OnPageChangeListener() {
				@Override
				public void onPageSelected(int position) {
					// 选择指定的页面事件
					selectNavImg(position);
				}
	
				/**
				 * 位置，偏移量，偏移像素大小
				 */
				@Override
				public void onPageScrolled(int position, float offset, int offsetpix) {
					// 滚动状态中的处理方法
					Log.i("info", "-- onPageScrolled -- "+offset+" -- "+offsetpix);
				}
	
				@Override
				public void onPageScrollStateChanged(int state) {
					// 滚动状态变化的事件
					switch (state) {
					case ViewPager.SCROLL_STATE_DRAGGING: // 开始滚动
						Log.i("info", "SCROLL_STATE_DRAGGING -- 开始滚动");
						break;
					case ViewPager.SCROLL_STATE_IDLE: // 停止滚动
						Log.i("info", "SCROLL_STATE_IDLE -- 停止滚动");
						break;
	
					case ViewPager.SCROLL_STATE_SETTLING: // 滚动正在准备显示下个页面
						Log.i("info", "SCROLL_STATE_SETTLING -- 滚动正在准备显示下个页面");
						break;
					default:
						break;
					}
				}
			});
	
		}
	
		// 取得当前设置导航的状态
		public void selectNavImg(int position) {
			ImageView imgView = null;
			for (int i = 0; i < navLayout.getChildCount(); i++) {
				// 获取指定位置的子控件
				imgView = (ImageView) navLayout.getChildAt(i);
				if (i == position) {
					imgView.setImageResource(R.drawable.icon_choose_dot_s);
				} else {
					imgView.setImageResource(R.drawable.icon_choose_dot_n_1);
				}
			}
	
		}
	
		class MyPagerAdapter extends PagerAdapter {
			// 获取当前窗体的界面数
			@Override
			public int getCount() {
				return views.size();
			}
	
			// 判断对象是否是由界面生成
			@Override
			public boolean isViewFromObject(View arg0, Object arg1) {
				return arg0 == arg1;
			}
	
			// 当前适配器选择那个对象放在ViewPager上面
			@Override
			public Object instantiateItem(ViewGroup container, int position) {
				container.addView(views.get(position)); // 添加到容器中
				return views.get(position);
			}
	
			// 销毁当前那个View
			@Override
			public void destroyItem(ViewGroup container, int position, Object object) {
				container.removeView(views.get(position));
			}
		}
	}



![android_viewpager01.png]({{site.baseurl}}/public/img/android_viewpager01.png)

流程：

1. 创建PagerAdapter，和item控件列表
2. 添加子控件到adapter中
3. 将控件设置给ViewPager

![android_viewpager02.png]({{site.baseurl}}/public/img/android_viewpager02.png)

