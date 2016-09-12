---
layout: post
title:  "Android 学习记录 - 网络读取json 回调设置Spinner adapter"
date: 2015/11/17 17:05:56 
categories:
- 技术
tags:
- Android
---

通过回调函数设置list下拉框从网络读取json值进行设置

### 基本类：

![android_spinner01]({{site.baseurl}}/public/img/android_spinner01.png)

### FeedCategory：实体类

	public class FeedCategory {
		private int id ;
		private String name;
		public int getId() {
			return id;
		}
		public void setId(int id) {
			this.id = id;
		}
		public String getName() {
			return name;
		}
		public void setName(String name) {
			this.name = name;
		}
		@Override
		public String toString() {
			return "id="+this.getId()+",name="+this.getName();
		}
	}

### 工具类

- CategroyTask：解析JSON后返回List<FeedCategory>集合，其中使用回调接口CallBack来将数据返回给主线程；

		public class CategroyTask extends AsyncTask<String, Void, List<FeedCategory>> {
			private CallBack callback;
			public CategroyTask(CallBack callback){
				this.callback=callback;
			}
			@Override
			protected List<FeedCategory> doInBackground(String... params) {
				try{
					byte[] bytes=Request.get(params[0]);
					if(bytes!=null){
						String json=new String(bytes,"utf-8");
						JSONArray jsonArray=new JSONObject(json).getJSONObject("paramz").getJSONArray("columns");
						List<FeedCategory> list=new ArrayList<FeedCategory>();
						for(int i=0;i<jsonArray.length();i++){
							FeedCategory fc=new FeedCategory();
							fc.setId( jsonArray.getJSONObject(i).getInt("id") );
							fc.setName( jsonArray.getJSONObject(i).getString("name") );
							list.add(fc);
						}
						return list;
					}else{
						
					}
				}catch(Exception e){
					
				}
				return null;
			}
			
			@Override
			protected void onPostExecute(List<FeedCategory> result) {
				if(result!=null){
					callback.response(result);
				}
			}
			public interface CallBack{
				 public void response(List<FeedCategory> list);
			}
		}

- Request: 从网络读取json格式的数据对象

		public class Request {
			//从一个URL地址取得对象流；
			public static byte[] get(String url) throws Exception{
				HttpClient client =new DefaultHttpClient();
				HttpResponse response=client.execute(new HttpGet(url));
				if(response.getStatusLine().getStatusCode()==HttpStatus.SC_OK){
					return EntityUtils.toByteArray(response.getEntity());
				}
				return null;
			}
		}

- Urls：存放连接地址常量；

		public class Urls {
			public static final String BASE_URL="http://litchiapi.jstv.com/";
			
			//分类
			public static final String CATEGORY_URL=BASE_URL+"api/GetColumns?client=android&val=B52F2195EB64517ABC31C550BBFC5AEC";
			
			//列表信息
			public static final String LIST_URL=BASE_URL+"api/GetFeeds?column=%d&PageSize=20&pageIndex=1&val=100511D3BE5301280E0992C73A9DEC41";
		}


### 主类

MainActivity：通过调用回调函数，直接取得链接对象的json后传给datas并且设置adapter

		//通过回调进行设置从网络取得的值
		new CategroyTask(new CategroyTask.CallBack(){
			@Override
			public void response(List<FeedCategory> list) {
				datas.addAll(list);
				adapter.notifyDataSetChanged();
			}
		}).execute(Urls.CATEGORY_URL);

运行截图：

![android_spinner02]({{site.baseurl}}/public/img/android_spinner02.png)



----------


## 11/18日补充

![android_new02.PNG]({{site.baseurl}}/public/img/android_new02.png)

### FeedAdapter.java

继承BaseAdapter 用来构造Feed中的适配器，设置item中的各组件是属性值；

	private Context context;
	private List<Feed> feedlist;
	
	//定义线程池；
	private ExecutorService executor=Executors.newFixedThreadPool(3) ;
	
	//定义缓存
	private Map<String,SoftReference<Bitmap>> imgCaches=new HashMap<String, SoftReference<Bitmap>>();
	
	//省略代码....；
	
	@Override
	public View getView(int position, View convertView, ViewGroup parent) {

		View itemView=LayoutInflater.from(context).inflate(R.layout.item_feed, null);
		
		TextView subjectView=(TextView) itemView.findViewById(R.id.subjectView);
		TextView summaryView=(TextView) itemView.findViewById(R.id.summaryView);
		
		final ImageView coverView=(ImageView) itemView.findViewById(R.id.coverId);
		subjectView.setText(feedlist.get(position).getSubject());
		summaryView.setText(feedlist.get(position).getSummary());

		final String imgUrl=Urls.BASE_URL+feedlist.get(position).getCover();
		
		SoftReference<Bitmap> sr=imgCaches.get(imgUrl);
		if(sr!=null){
			Bitmap bm=sr.get();
			if(bm!=null){
				coverView.setImageBitmap(bm);
			}else{
				getImage(coverView, imgUrl);
			}
		}else{
			getImage(coverView, imgUrl);
		}
		return itemView;
	}

	private void getImage(final ImageView coverView, final String imgUrl) {
		//下载图片
		new ImageTask(new ImageTask.CallBack(){
			@Override
			public void response(String url, Bitmap bitmap) {
				coverView.setImageBitmap(bitmap);
				imgCaches.put(url, new SoftReference<Bitmap>(bitmap));
			}
		}).executeOnExecutor(executor,imgUrl);
	}

说明：

>getView(int position, View convertView, ViewGroup parent): 用来取得List对象中的ItemView，并且将值放到其中的Item对象中；
>
>executeOnExecutor(Executor exec, String... params)：用线程池中的数据来下载图片；
>
>LayoutInflater.from(context).inflate(int resource, ViewGroup root)：找到相应的布局文件实例化；resource:是布局文件ID，root：是Layout文件中的根视图；若是提供了root,root则是生成的层次结构的根视图，否则是整个视图；


### FeedTask.java

用来解析JSON中数据放入List<Feed>集合中；

	public class FeedTask extends AsyncTask<String, Void, List<Feed>> {
		private CallBack callback;
		public FeedTask(CallBack callback){
			this.callback=callback;
		}
		@Override
		protected List<Feed> doInBackground(String... params) {
			try{
				byte[] bytes=Request.get(params[0]);
				if(bytes!=null){
					String json=new String(bytes,"utf-8");
					JSONArray jsonArray=new JSONObject(json).getJSONObject("paramz").getJSONArray("feeds");
					List<Feed> list=new ArrayList<Feed>();
					for(int i=0;i<jsonArray.length();i++){
						Feed f=new Feed();
						f.setId( jsonArray.getJSONObject(i).getInt("id") );
						f.setOid( jsonArray.getJSONObject(i).getInt("oid") );
						f.setSubject( jsonArray.getJSONObject(i).getJSONObject("data").getString("subject") );
						f.setSummary( jsonArray.getJSONObject(i).getJSONObject("data").getString("summary") );
						f.setCover( jsonArray.getJSONObject(i).getJSONObject("data").getString("cover") );
						
						list.add(f);
					}
					return list;
				}
			}catch(Exception e){
				
			}
			return null;
		}
		
		@Override
		protected void onPostExecute(List<Feed> result) {
			if(result!=null){
				callback.response(result);
			}
		}
		
		public interface CallBack{
			public void response(List<Feed> list);
		}
	}


### ImageTask.java

用来解析图片连接地址返回的Bitmap对象；
	
	public class ImageTask extends AsyncTask<String, Void, Bitmap> {
		private CallBack callback;
		private String url;
		public ImageTask(CallBack callback){
			this.callback=callback;
		}
		@Override
		protected Bitmap doInBackground(String... params) {
			try{
				url=params[0];
				byte[] bytes=Request.get(url);
				if(bytes!=null){
					return BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
				}
			}catch(Exception e){
				
			}
			return null;
		}
		
		@Override
		protected void onPostExecute(Bitmap result) {
			if(result!=null){
				callback.response(url,result);
			}
		}
		public interface CallBack{
			 public void response(String url,Bitmap bitmap);
		}
	}

运行截图：

![android_new03.PNG]({{site.baseurl}}/public/img/android_new03.png)
