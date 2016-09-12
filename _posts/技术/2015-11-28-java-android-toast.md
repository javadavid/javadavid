---
layout: post
title:  "Android Toast 学习记录"
date: 2015/11/28 12:09:36 
categories:
- 技术
tags:
- Android
---


### 实例化

分为2种，实现起来比较简单

- 构造方法实例化，Toast(Context context)
- 静态方法实例化，makeText(Context context, CharSequence text, int duration)


### 代码：
	public void showTosat01(View view){
		Toast toast=new Toast(getApplicationContext());
		
		TextView tv=new TextView(getApplicationContext());
		tv.setText("这个是实例化构造的Toast方法");
		tv.setTextColor(Color.RED);
		tv.setPadding(20, 20, 20, 20);
		tv.setBackgroundColor(Color.argb(128,0,0,0));		//设置 透明度和颜色背景
		
		//tv.setAlpha(0.5f);	//设置透明度
		//将toast设置到textView
		toast.setView(tv);
		toast.setDuration(Toast.LENGTH_LONG);	//设置显示的时间
		
		//设置显示的位置;后面2个参数是表示偏移量。	120px/(320/160)	--> 60dp
		toast.setGravity(Gravity.BOTTOM|Gravity.CENTER_HORIZONTAL, 0, 320);
		
		toast.show();
	}
	
	public void showTosat02(View view){
		Toast toast=Toast.makeText(getApplicationContext(), "Toast 静态构造创建...", Toast.LENGTH_LONG);
		toast.setGravity(Gravity.CENTER|Gravity.FILL_HORIZONTAL , 0, 0);
	
		toast.show();
	}

![android_tosat01.png]({{site.baseurl}}/public/img/android_tosat01.png)
![android_tosat02.png]({{site.baseurl}}/public/img/android_tosat02.png)

### 说明：
- Color.argb(int alpha, int red, int green, int blue)：设置颜色和透明度
- setGravity(int gravity, int xOffset, int yOffset)：设置Toast的位置和偏移量
	- 偏移量是相对应当前设置的位置来加减（单位是dp）





