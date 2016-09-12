---
layout: post
title:  "Android AutoCompleteTextView 学习记录"
date: 2015/11/17 10:17:44  
categories:
- 技术
tags:
- Android
---

## 解释
>AutoCompleteTextView: 用来显示提示信息的控件

继承关系如下：继承于TextView - EditText
	
	java.lang.Object
	  android.view.View
	      android.widget.TextView
	          android.widget.EditText
	              android.widget.AutoCompleteTextView

其中监听的方法：

## 事件	
1. 点击item发生的事件
		
		actView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
	
			@Override
			public void onItemClick(AdapterView<?> parent, View v, int position,long id) {
				CharSequence txt=((TextView)v).getText();
				setTitle(txt);
				Toast.makeText(getApplicationContext(),"text->"+txt,Toast.LENGTH_LONG).show();
			}
		});


2. 监听文本框改变事件
	
		actView.addTextChangedListener(new TextWatcher() {
		
			@Override
			public void onTextChanged(CharSequence s, int start, int before, int count) {
				// TODO 自动生成的方法存根
				Log.i("info", "-- onTextChanged --" + s.toString());
			}
			
			@Override
			public void beforeTextChanged(CharSequence s, int start, int count,
					int after) {
				// TODO 自动生成的方法存根
				Log.i("info", "-- beforeTextChanged --" + s.toString());
			}
			
			@Override
			public void afterTextChanged(Editable s) {
				// TODO 自动生成的方法存根
				Log.i("info", "-- afterTextChanged --" + s.toString());
			}
		});
		
它的执行顺序和结果如下：

![android_autocompleteTextView01.PNG]({{site.baseurl}}/public/img/android_autocompleteTextView01.png)


在layout XML配置文件中
	
	//配置输入多少字符进行提示
	android:completionThreshold="1"
	//输入法的文本类型
	android:inputType="text"




### 实例

下面利用afterTextChanged查找字符串；详细项目ListView01

ArrayAdapter是用来保存ListView组件中的item数据的组件

- public void afterTextChanged(Editable s)：当用户输入完成后调用的方法；
- adapter.notifyDataSetChanged()：用来调用当ListView数据有变化时的数据重载

		public class MainActivity extends Activity {
			private AutoCompleteTextView actview;
			private ListView listView;	//下拉框显示的list列表
			private List<String> datas;	//存放原始列表数据
			private List<String> words;	//存放查找数据
			private ArrayAdapter<String> adapter;	//adapter适配器
			
			@Override
			protected void onCreate(Bundle savedInstanceState) {
				super.onCreate(savedInstanceState);
				setContentView(R.layout.activity_main);
				//先实例化各个初始值；
				actview=(AutoCompleteTextView) findViewById(R.id.actvId);
				listView= (ListView) findViewById(R.id.lvId);
				
				datas=new ArrayList<String>();
				
				adapter=new ArrayAdapter<String>(getApplicationContext(),R.layout.item_view,datas);
				
				listView.setAdapter(adapter);
				
				loadWords();	//启动时候，载入初始数据
				actview.addTextChangedListener(new TextWatcher() {
					@Override
					public void onTextChanged(CharSequence s, int start, int before, int count) {
					}
					
					@Override
					public void beforeTextChanged(CharSequence s, int start, int count, int after) {
					}
					
					@Override
					public void afterTextChanged(Editable s) {
						Log.i("sys", "afterTextChanged"+s);
						datas.clear();
						if(s.length()>0){
							for(String word:words){
								if(word.indexOf(s.toString())!=-1){
									datas.add(word);
								}
							}
						}else{
							datas.addAll(words);
						}
						adapter.notifyDataSetChanged();	//
					}
				});
			}
		
			private void loadWords() {
				words=new ArrayList<String>();
				//随机生成字符串放入到words 和 datas 中；
				for(int i=0;i<50;i++){
					char[] c=new char[10];
					for(int j=0;j<c.length;j++){
						c[j]=(char) ('a'+(Math.random()*25));
					}
					words.add(new String(c));
				}
				datas.addAll(words);
				//adapter.notifyDataSetChanged();
			}
		}

运行截图：

![android_autocompleteTextView02.PNG]({{site.baseurl}}/public/img/android_autocompleteTextView02.png)