---
layout: post
title:  "Android Service - DownLoadManager"
date: 2016/2/14 18:54:45 
categories:
- 技术
tags:
- Android
---

### Service系统服务（DownLoadManager）
android系统提供的一个自带的下载服务组件位于android.app包中

下面来看它的使用：

- 初始通过context.getSystemService实例化DownLoadManager组件
- 使用其子类Request设置相应下载参数
- 将request添加到实例化的下载管理器中进行下载


		public class MainActivity extends Activity {
		
			private String downloadUrl = "https://www.baidu.com/img/270_7573fb368053e6805e63b56352ce7287.gif";
			
			private DownloadManager dlManager;
			
		    @Override
		    protected void onCreate(Bundle savedInstanceState) {
		        super.onCreate(savedInstanceState);
		        setContentView(R.layout.activity_main);
		        dlManager = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
		    }
		
		    public void downLoad(View v){ 
		    	DownloadManager.Request request = new DownloadManager.Request(Uri.parse(downloadUrl));
		    	
		    	//设置下载文件路径
		    	request.setDestinationInExternalPublicDir(Environment.DIRECTORY_PICTURES,"1.gif");
		    	
		    	//设置通知是否可见
		    	request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE | 
		    				DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
		    
		    	request.setTitle("正在下载文件 1.gif");
		    	
		    	//压入队列 开始下载文件；
		    	dlManager.enqueue(request);	
		    }
		}

![android_service09.png]({{site.baseurl}}/public/img/android_service09.png)




