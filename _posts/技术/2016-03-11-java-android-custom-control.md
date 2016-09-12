---
layout: post
title:  "Android 自定义控件 "
date: 2016/3/11 14:55:11 
categories:
- 技术
tags:
- Android
---

### 扩展基本控件 - 文本控件 （TextView）
1. 创建基本控件的子类，构造Context对象的方法；
2. 重写其中绘制方法onDraw(Canvas canvas)和触摸方法onTouchEvent(MotionEvent event);

onDraw()：设置画笔Paint，通过Canvan进行绘制圆形和直线

onTouchEvent()：判断抬起和按下的状态，计算坐标 并且移动重绘图像layout();

	public class MyTextView extends TextView { 
		
		public MyTextView(Context context, AttributeSet attrs) {
			super(context, attrs); 
		}
	
		@Override
		@ExportedProperty(category = "text")
		public float getTextSize() {
			//当前字体像素 * 屏幕密度；
			return super.getTextSize()*getResources().getDisplayMetrics().density;
		}
		
		@Override
		protected void onDraw(Canvas canvas) {
			// 绘制当前控件的信息
			super.onDraw(canvas);
			
			Paint paint = new Paint();
			paint.setColor(Color.RED);
			paint.setStrokeWidth(10);
			paint.setAntiAlias(true);//抗锯齿
			paint.setTextAlign(Align.CENTER);
			
			//左
			canvas.drawLine(0, 0, 0, getHeight(), paint);
			
			//右
			canvas.drawLine(getWidth(), 0, getWidth(), getHeight(), paint);
			
			//上
			canvas.drawLine(0, 0, getWidth(), 0, paint);
			
			//下
			canvas.drawLine(0, getHeight(), getWidth(), getHeight(), paint);
			
			//画图
			Bitmap bitmap = BitmapFactory.decodeResource(getResources(), android.R.drawable.ic_media_play);
			
			//新的画图工具绘制圆
			Paint cpaint = new Paint();
			cpaint.setColor(Color.GRAY);
			cpaint.setStyle(Style.FILL);
			cpaint.setAlpha(200);
			cpaint.setAntiAlias(true);
			canvas.drawCircle(getWidth()/2, getHeight()/2, bitmap.getWidth()/2, cpaint);
			
			int top = (getHeight() - bitmap.getHeight())/2 ; 
			int left = (getWidth() - bitmap.getWidth())/2 ; 
			
			canvas.drawBitmap(bitmap, left, top, paint);
			
		}
		
		private float down_x ,down_y;
		
		@Override
		public boolean onTouchEvent(MotionEvent event) {
	
			switch (event.getAction()) {
				case MotionEvent.ACTION_UP:
					//setBackgroundColor(Color.GRAY);  
					break;
				case MotionEvent.ACTION_DOWN:
					setBackgroundColor(Color.BLUE);
					//取得自定义文本的相对点击位置
					down_x = event.getX();
					down_y = event.getY(); 
					break;
				case MotionEvent.ACTION_MOVE:
					setBackgroundColor(Color.YELLOW);
					
					//取得自定义文本的相对点击位置
					float move_x = event.getX();
					float move_y = event.getY();
					
					//取得文本到Layout的距离
					int offsetX = (int) (move_x - down_x) ;
					int offsetY = (int) (move_y - down_y) ;
					
					layout(getLeft() + offsetX, getTop() + offsetY, getRight() + offsetX,getBottom() + offsetY); 
					break;
				default:
					break;
			}
			return true;	//表示UI处理全部事件；
		}
	}
	
	
![custom_control01.png]({{site.baseurl}}/public/img/custom_control01.png)


