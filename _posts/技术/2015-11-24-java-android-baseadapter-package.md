---
layout: post
title:  "Android BaseAdapter 学习记录 - 重构 "
date: 2015/11/24 17:00:12 
categories:
- 技术
tags:
- Android
---

BaseAdapter的重构；

以前adapter方法：直接继承BaseAdapter 关联 使用ViewHolder 定义ListView的填充类型；代码如下

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		Person p=datas.get(position);
		ViewHolder viewHolder=null;
		if(getItemViewType(position)==Person.TYPE_TITLE){
			if(convertView==null){
				viewHolder=new ViewHolder();
				convertView=LayoutInflater.from(context).inflate(R.layout.item_person_title, null);
				viewHolder.nameView=(TextView) convertView.findViewById(R.id.titleId);
				convertView.setTag(viewHolder);
			}else{
				viewHolder=(ViewHolder)convertView.getTag();
			}
			viewHolder.nameView.setText(p.getName());
		}else{
			if(convertView==null){
				viewHolder=new ViewHolder();
				convertView=LayoutInflater.from(context).inflate(R.layout.item_person_data, null);
				viewHolder.nameView=(TextView) convertView.findViewById(R.id.nameId);
				viewHolder. sexView=(TextView) convertView.findViewById(R.id.sexId);
				viewHolder. ageView=(TextView) convertView.findViewById(R.id.ageId);
				viewHolder. telView=(TextView) convertView.findViewById(R.id.telId);
				convertView.setTag(viewHolder);
			}else{
				viewHolder=(ViewHolder) convertView.getTag();
			}
			viewHolder.nameView.setText(p.getName());
			viewHolder.sexView.setText(p.getSex());
			viewHolder.ageView.setText(String.valueOf(p.getAge()));
			viewHolder.telView.setText(p.getTel());
		}
		convertView.setClickable(false);
		return convertView;
	}
	
	class ViewHolder{
		TextView nameView,sexView,ageView,telView;
	}


另外一种可以直接封装adapter,使用者决定填充题的对象；

		public abstract class AbsAdapter<T> extends BaseAdapter {
		private Context context;
		private List<T> datas;
		private int layoutRes;
		public AbsAdapter(Context context,int layoutRes, List<T> datas) {
			this.context = context;
			this.datas = datas;
			this.layoutRes = layoutRes;
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
	
		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			ViewHolder viewHolder=null;
			if(convertView==null){
				convertView=LayoutInflater.from(context).inflate(layoutRes,null);
				viewHolder=new ViewHolder(convertView);
				convertView.setTag(viewHolder);
			}else{
				viewHolder=(ViewHolder) convertView.getTag();
			}
			showData(viewHolder, datas.get(position));
			return convertView;
		}
	
		//将存放的子布局的传过去给调用者， 填充的类型都由调用者决定
		public abstract void showData(ViewHolder<T> viewHolder,T data); 
		
		public class ViewHolder<T>{
			private Map<Integer,View> views;	//定义ViewHolder中的对象键值对；
			private View itemView;
	
			public ViewHolder(View itemView) {	//传入布局的子布局LayoutView
				this.itemView=itemView;
				views=new HashMap<Integer,View>();
			}
			public View getViews(int resourceId) {	//根据ID取得子布局中的对象
				View view=views.get(resourceId);
				if(view==null){
					view=itemView.findViewById(resourceId);
					views.put(resourceId, view);
				}
				return view;
			}
		}
	}


调用方：实现Adapter和填充相应数据

	public class MainActivity extends Activity {
		private List<Person> datas;
		private ListView lv;
		private AbsAdapter<Person> adapter;
		
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
			lv=(ListView) findViewById(R.id.lvId);
			datas=new ArrayList<Person>();
			adapter=new AbsAdapter<Person>(getApplicationContext(),R.layout.item_person,datas) {
				@Override
				public void showData(ViewHolder<Person> viewHolder, Person data) {
					
					TextView nameView=(TextView) viewHolder.getViews(R.id.nameId);
					TextView ageView=(TextView) viewHolder.getViews(R.id.ageId);
					TextView sexView=(TextView) viewHolder.getViews(R.id.sexId);
					
					nameView.setText(data.getName());
					ageView.setText(String.valueOf(data.getAge()));
					sexView.setText(data.getSex());
					
				}
			};
			lv.setAdapter(adapter);
			
			loadData();
		}
	
		private void loadData() {
			for(int i=0;i<10;i++){
				Person p=new Person("zhangsan - "+i,Math.random()>0.5?"男":"女",(int)(Math.random()*10+20));
				datas.add(p);
			}
		}
	}

运行结果和原来的ListView一样:

![android_adapter02.PNG]({{site.baseurl}}/public/img/android_adapter02.png)