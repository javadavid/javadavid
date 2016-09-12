---
layout: post
title:  "Android Fragment 学习记录(3)"
date: 2015/12/3 17:57:25 
categories:
- 技术
tags:
- Android
---

### LinkList动态添加Fragment碎片

Fragment，activity_main.xml：

	<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" 
	    android:orientation="vertical">
	    <Button
	        android:id="@+id/addId"
	        android:layout_width="fill_parent"
	        android:layout_height="wrap_content"
	        android:onClick="addFragment"
	        android:text="增加" />
	    <Button
	        android:id="@+id/backId"
	        android:layout_width="fill_parent"
	        android:layout_height="wrap_content"
	        android:onClick="backFragment"
	        android:text="返回" />
	    <FrameLayout
	        android:id="@+id/fragmentId"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"/>
	</LinearLayout>

fragment_item.xml:

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <TextView
	        android:id="@+id/tvId"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"
	        android:text="@string/hello_world" 
	        android:gravity="center"/>
	</RelativeLayout>


Fragment：ContentFragment

	public class ContentFragment extends Fragment {
		private static final String TAG="ContentFragment";
		private Long msg;
		@Override
		public void onAttach(Activity activity) {
			msg=getArguments().getLong("msg");
			super.onAttach(activity);
		}
		
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) {
			Log.i("info",TAG+"-- onCreateView --");
			View view=inflater.inflate(R.layout.fragment_item,null);	//通过资源文件取得Layout
			TextView tv=(TextView) view.findViewById(R.id.tvId);
			tv.setBackgroundColor(Color.rgb((int)(Math.random()*256),(int)(Math.random()*256), (int)(Math.random()*256)));
			tv.setText(String.valueOf(msg));
			return view;
		}
	}	


MainActivity的按钮事件：

- 添加
	- 创建对象，并且将Fragment对象添加到LinkList（堆栈）中。后续可以栈入栈出操作
	- 创建Bundle，通过setArguments设置到对象中。
	- FragmentTransaction的add/hide/remove/show方法来来对Fragment数据列表添加，隐藏，移除和显示。最后commit提交刷新Fragment。
- 返回操作
	- 现将LinkList栈顶的对象移除，然后LinkList若不是空，则在将其栈顶的元素显示出来

<nobr/>

	public class MainActivity extends Activity {
		private LinkedList<Fragment> fragments=new LinkedList<Fragment>();
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
		}
		
		//动态显示Fragment
		public void addFragment(View view) {
			//实例化Fragment
			ContentFragment cFragment=new ContentFragment();
			
			Bundle args=new Bundle();
			args.putLong("msg", System.currentTimeMillis());
			
			cFragment.setArguments(args);
			
			//removePre(getFragmentManager().beginTransaction());	//删除当前的碎片
	
			if(fragments.isEmpty()){
				getFragmentManager().beginTransaction().add(R.id.fragmentId, cFragment,"content").commit();
			}else{
				getFragmentManager().beginTransaction().hide(fragments.peek()).add(R.id.fragmentId, cFragment,"content").commit();
			}
			
			fragments.push(cFragment);
		}
	
		private void removePre(FragmentTransaction transaction) {
			//将Fragment添加到布局文件中	第一个参数是Fragment布局的ID资源文件
			Fragment preFragment=getFragmentManager().findFragmentByTag("content");
			if(preFragment!=null){
				transaction.remove(preFragment);
			}
		}
		
		public void backFragment(View view) {
			if(!fragments.isEmpty()){
				getFragmentManager().beginTransaction().remove(fragments.poll()).commit();
				if(!fragments.isEmpty()){
					getFragmentManager().beginTransaction().show(fragments.peek()).commit();
				}
			}
		}
	}

对象只有在点击创建的时候才会触发fragment中的onCreateView方法。返回操作是通过LinkList中保存的对象在重新显示的。

![android_fragment06.png]({{site.baseurl}}/public/img/android_fragment06.png)



### 系统回退栈 动态添加Fragment碎片

Fragment的实例化都是一样的，参考上面代码


主视图添加回退Fragment操作

- 实例化Fragment对象
- 通过FragmentTransaction，replace方法进行替换Fragment
- addToBackStack(null) 加入回退流
- 返回操作通过onBackPressed()方法：通过返回手机的返回按钮返回操作

<nobr/>

	public class MainActivity extends Activity {
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
		}
		
		//动态显示Fragment
		public void addFragment(View view) {
			//实例化Fragment
			ContentFragment cFragment=new ContentFragment();
			
			Bundle args=new Bundle();
			args.putLong("msg", System.currentTimeMillis());
			
			cFragment.setArguments(args);
			
			//获取Fragment对象
			FragmentTransaction ft=getFragmentManager().beginTransaction();
			ft.replace(R.id.fragmentId, cFragment);
			ft.addToBackStack(null);//将Fragment放到默认的堆栈中，name标识栈的标识符；
			ft.commit();
		}
	
		public void backFragment(View view) {
			onBackPressed();
		}
	}

点击增加时候：会创建当前Fragment，删除前一个Fragment。

![android_fragment07.png]({{site.baseurl}}/public/img/android_fragment07.png)


点击返回时候同样：会创建当前Fragment，删除前一个Fragment。和LinkedList创建方式不一样。（上面一种是直接将Fragment保存在链表中）

![android_fragment08.png]({{site.baseurl}}/public/img/android_fragment08.png)


----
切换Fragment实例：

android_fragment09.png

activity_main.xml：设置横屏和竖屏（layout-land）的layout

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <!-- 静态设置Fragment -->
	    <fragment
	        android:id="@+id/fragmentId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:name="com.example.fragment.LeftFragment" />
	</RelativeLayout>

	<!-- 竖屏Layout -->
	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".MainActivity" >
    <fragment
        android:id="@+id/fragmentId"
        android:name="com.example.fragment.LeftFragment"
        android:layout_width="200dp"
        android:layout_height="fill_parent" />
	<!-- 动态加载Fragment -->
    <FrameLayout
        android:id="@+id/fragmentView"
        android:layout_width="wrap_content"
        android:layout_height="fill_parent"
        android:layout_toRightOf="@id/fragmentId" />
	</RelativeLayout>

LeftFragment.java：

- onAttach：开始和主activity交互时候，添加datas文件列表，设置adapter适配器
- onCreateView：用来创建将列表放入adapter
- onActivityCreated：用来添加ListView的item点击事件，通过动态加载bundle对象传过来的参数来决定是调用activity（ContentActivity）还是fragment（ContentFragment）。
- getResources().getConfiguration().orientation==Configuration.ORIENTATION_LANDSCAPE：判断是横屏还是竖屏的状态；

<nobr/>

	public class LeftFragment extends Fragment{
		private List<String> datas=new ArrayList<String>();
		private ArrayAdapter<String> adapter;
		private ListView lvView;
		@Override
		public void onAttach(Activity activity) {
			super.onAttach(activity);
			datas.add("day1.txt");
			datas.add("day2.txt");
			datas.add("day3.txt");
			datas.add("day4.txt");
			datas.add("day5.txt");
			datas.add("day6.txt");
			adapter=new ArrayAdapter<String>(getActivity(),R.layout.day_activity,datas);
		}
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) {
			lvView = (ListView) inflater.inflate(R.layout.fragment_left, null);
			lvView.setAdapter(adapter);
			return lvView;
		}
		@Override
		public void onActivityCreated(Bundle savedInstanceState) {
			lvView.setOnItemClickListener(new OnItemClickListener() {
				@Override
				public void onItemClick(AdapterView<?> adapter, View view, int position,long id) {
					Toast.makeText(getActivity(), datas.get(position),1).show();
					Bundle args=new Bundle();
					args.putString("day", datas.get(position));
					if(getResources().getConfiguration().orientation==Configuration.ORIENTATION_LANDSCAPE){
						ContentFragment cFragment=new ContentFragment();
						cFragment.setArguments(args);
						getFragmentManager().beginTransaction().replace(R.id.fragmentView, cFragment).addToBackStack(null).commit();
					}else{
						Intent intent=new Intent(getActivity(),ContentActivity.class);
						intent.putExtras(args);
						startActivity(intent);
					}
				}
			});
			super.onActivityCreated(savedInstanceState);
		}
	}

ContentActivity.java：将取得的Bundle直接传递到ContentFragment中然后直接显示

	public class ContentActivity extends Activity {
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_content);
			ContentFragment cFragment=new ContentFragment();
			cFragment.setArguments(getIntent().getExtras());
			
			getFragmentManager().beginTransaction().add(R.id.contentViewId, cFragment).commit();
			
		}
	}
	

ContentFragment.java

- onAttach：读取文件信息，放入全局变量textContent
- onCreateView：创建Fragment视图
- onActivityCreated：载入文本信息

	public class ContentFragment extends Fragment{
		private String textContent;
		private TextView txView;
		private String fileName;
		
		@Override
		public void onAttach(Activity activity) {
			super.onAttach(activity);
			//读取文件
			fileName=getArguments().getString("day");
			InputStream input;
			try {
				input = getResources().getAssets().open(fileName);
				BufferedReader bf=new BufferedReader(new InputStreamReader(input));
				StringBuilder sb=new StringBuilder();
				String s;
				while ((s=bf.readLine())!=null) {
					sb.append(s+"\n");
				}
				textContent=sb.toString();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState){
			View view= inflater.inflate(R.layout.fragment_content,null);
			txView = (TextView) view.findViewById(R.id.contentTxView); 
			return view;
		}
		
		@Override
		public void onActivityCreated(Bundle savedInstanceState) {
			super.onActivityCreated(savedInstanceState);
			txView.setText(textContent);
		}
	}

![android_fragment10.png]({{site.baseurl}}/public/img/android_fragment10.png) ![android_fragment11.png]({{site.baseurl}}/public/img/android_fragment11.png)


由于我本机模拟器版本的问题，无法横屏，所以这个就自己使用真机运行吧，就不截图了。



