---
layout: post
title:  "Android Handler 学习记录（实例）"
date: 2016/1/9 17:32:33 
categories:
- 技术
tags:
- Android
---


通过Handler子线程下载解析数据 显示LisView列表；（Handler04）

相应的类：

- URLs.java：保存URL地址；
- Feed.java/FeedData.java：分别是Json的字段；

![android_handler04.png]({{site.baseurl}}/public/img/android_handler04.png)

AUtil.java：

- 创建子线程（池）,用于下载图片和json
- 子线程通过判断对象类型并且将解析的数据保存到msg.obj中
- Handler将数据中发送给主线程；

<nobr/>

	public class AUtil {
		public static final int TYPE_TXT=1;
		public static final int TYPE_IMG=2;
		
		private Handler mHandler;
		
		//声明一个线程池
		public static ExecutorService executor=Executors.newFixedThreadPool(5);
		
		public AUtil(Handler mHandler){
			this.mHandler=mHandler;
		}
		
		public void getAsy(final int type,final String url){
			executor.execute(new Runnable() {
				@Override
				public void run() {
					try{
						HttpClient client=new DefaultHttpClient();
						HttpResponse response= client.execute(new HttpGet(url));
						if(response.getStatusLine().getStatusCode()== HttpStatus.SC_OK){
							byte[] data=EntityUtils.toByteArray(response.getEntity());
							
							Message msg=Message.obtain();
							msg.what=type;
							
							if(type==TYPE_TXT){
								String txt=new String(data,"utf-8");	
								msg.obj=txt;		//将JSON流保存给obj
							}else{
								Bitmap bitmap=BitmapFactory.decodeByteArray(data, 0, data.length);
								msg.obj=bitmap;		//将图片流保存给obj
								Bundle bundle=new Bundle();
								bundle.putString("url", url);	//并且将图片的URL地址绑定到图片，以后可以用findViewWithTag来取得图片
								msg.setData(bundle);
							}
							mHandler.sendMessage(msg);		//向主线程发送数据
						}
					}catch(Exception e ){
						e.printStackTrace();
					}
				}
			});
		}
	}


MainActivity.java：

- 调用后台子线程 ，启动初始化json数据
- 将子线程通过handleMessage方法接收，并且解析
- 并且在Item布局载入时候接收Image文件流（BitMap对象）

<nobr/>

	public class MainActivity extends Activity {
	
		private ListView lv;
		private List<Feed> datas;
		private FeedAdapter adapter;
		
		private Handler mHandler=new Handler(){
			@Override
			public void handleMessage(Message msg) {
				//取得子线程Handler处理后的数据
				if(msg.what==AUtil.TYPE_TXT){
					parseJson(String.valueOf(msg.obj));
				}else{
					String url=msg.getData().getString("url");
					ImageView imageView=(ImageView) lv.findViewWithTag(url);
					if(imageView!=null){
						imageView.setImageBitmap((Bitmap) msg.obj);
					}
				}
			}
		};
		
		AUtil autils;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lv=(ListView) findViewById(R.id.lvId);
			autils=new AUtil(mHandler);
			datas=new ArrayList<Feed>();
			adapter=new FeedAdapter(getApplicationContext(), datas,autils);
			
			lv.setAdapter(adapter);
			
			autils.getAsy(AUtil.TYPE_TXT, URLs.BASE_URI+URLs.URI);	//初始化下载Json数据
		}
		
		//解析json数据源
		private void parseJson(String json) {
			try {
				JSONArray array= new JSONArray(json);
				
				Gson gson=new Gson();
				TypeToken<List<Feed>> typeToken=new TypeToken<List<Feed>>(){};
				
				List<Feed> list=gson.fromJson(array.toString(), typeToken.getType());
				
				datas.clear();
				datas.addAll(list);
				adapter.notifyDataSetChanged();
				
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
	}


FeedAdapter.java

- 启动每一个Item对象调用子线程下载图片，返回给主线程
- 并且设置图片的Tag，方便主线程查找对象并设置ImageView对应的图片流

<nobr/>

	public class FeedAdapter extends BaseAdapter {
		private Context context;
		private List<Feed> datas;
		
		private AUtil autil;
		public FeedAdapter(Context context,List<Feed> datas,AUtil autil){
			this.context=context;
			this.datas=datas;
			this.autil=autil;
		}
		
		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			//对ListItem进行迭代保存
			ViewHodler vHodler = null;
			if(convertView==null){
				convertView=LayoutInflater.from(context).inflate(R.layout.item_feed, null);
				
				vHodler=new ViewHodler();
				vHodler.coverView=(ImageView) convertView.findViewById(R.id.coverId);
				vHodler.summaryView=(TextView) convertView.findViewById(R.id.summaryId);
				vHodler.subjectView=(TextView) convertView.findViewById(R.id.subjectId);
			
				convertView.setTag(vHodler);
			}else{
				vHodler=(ViewHodler) convertView.getTag();
				vHodler.coverView.setImageResource(R.drawable.ic_launcher);
			}
			vHodler.summaryView.setText(datas.get(position).getData().getSummary());
			vHodler.subjectView.setText(datas.get(position).getData().getSubject());
			
			String imgURL=URLs.BASE_URI+datas.get(position).getData().getCover();
	
			vHodler.coverView.setTag(imgURL);
			
			autil.getAsy(AUtil.TYPE_IMG, imgURL) ;	//显示Item的时候调用线程下载图片
			
			return convertView;
		}
		
		class ViewHodler{
			TextView summaryView,subjectView;
			ImageView coverView;
		}
		
		
		@Override
		public int getCount() {
			return datas.size();
		}
	
		@Override
		public Object getItem(int position) {
			return datas.get(position);
		}
	
		@Override
		public long getItemId(int position) {
			return position;
		}
	}

总的来说：

- MainActivity.java主线程用来启动子线程，接收文件流对象，并且设置控件的显示信息
- AUtil.java：子线程通过判断是图片还是JSON文件，并且设置不同标识；
- FeedAdapter.java：设置除了图片以外的Item对象的信息，并且调用子线程


![android_handler05.png]({{site.baseurl}}/public/img/android_handler05.png)

