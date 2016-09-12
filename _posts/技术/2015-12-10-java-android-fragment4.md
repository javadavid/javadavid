---
layout: post
title:  "Android Fragment 学习记录(4) - DialogFragment"
date: 2015/12/10 9:07:48 
categories:
- 技术
tags:
- Android
---

### DialogFragment：对话框碎片(Fragment09)
- 通过覆写DialogFragment的onCreateDialog方法
	- 返回AlertDialog对象创建（newInstance创建一个单例的对象并且接受值）
	- onAttach时候接受 DialogInterface.OnClickListener对象实现回调

<nobr/>

	public class EditDialogFragment extends DialogFragment {
		private DialogInterface.OnClickListener listener;
		public static EditDialogFragment newInstance(Bundle args){
			EditDialogFragment f=new EditDialogFragment();
			f.setArguments(args);
			return f;
		}
		
		@Override
		public void onAttach(Activity activity) {
			super.onAttach(activity);
			if(activity instanceof DialogInterface.OnClickListener){
				listener=(OnClickListener) activity;
			}
		}
		@Override
		public Dialog onCreateDialog(Bundle savedInstanceState) {
			return new AlertDialog.Builder(getActivity())
					.setMessage(getArguments().getString("msg"))
					.setPositiveButton("确定", listener)
					.setNegativeButton("取消", null)
					.setTitle(getArguments().getString("title"))
					.setIcon(android.R.drawable.ic_media_play)
					.create();
		}
	}

activity_main.xml：

	<Button
	        android:id="@+id/btnId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:onClick="showDialog"
	        android:text="显示  DialogFragment" />

MainActivity.java：

- 通过EditDialogFragment.newInstance(bundle)回调创建显示Fragment
- 实现OnClickListener，通过bundle对象中的type的值区别是finish结束还是显示Toast


<nobr/>

	public class MainActivity extends Activity implements OnClickListener{
		private EditDialogFragment df;
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
		}
		
		public void showDialog(View view){
			df=(EditDialogFragment) getFragmentManager().findFragmentByTag("dialog");
			if(df==null){
				Bundle bundle=new Bundle();
				bundle.putString("msg", "正在显示DialogFragment消息");
				bundle.putString("title", "DialogFragment标题");
				bundle.putString("type", "1");
				df=EditDialogFragment.newInstance(bundle);
			}
			//只创建一个对话框Fragment对象
			df.show(getFragmentManager(), "dialog");
		}
	
		@Override
		public void onClick(DialogInterface dialog, int which) {
			if(df.getArguments().getString("type").equals("1")){
				Toast.makeText(this, "点击对话框", 1).show();
			}else{
				finish();
			}
		}
		
		@Override
		public boolean onKeyDown(int keyCode, KeyEvent event) {
			if(keyCode==KeyEvent.KEYCODE_BACK){
				Bundle bundle=new Bundle();
				bundle.putString("msg", "确定退出吗");
				bundle.putString("title", "DialogFragment标题");
				bundle.putString("type", "2");
				df=EditDialogFragment.newInstance(bundle);
				df.show(getFragmentManager(), "exitdialog"); 
			}
			return false;
		}
	}

![android_fragment12.png]({{site.baseurl}}/public/img/android_fragment12.png)

点击返回键：

![android_fragment13.png]({{site.baseurl}}/public/img/android_fragment13.png)


- 通过onCreateView创建

fragment_exitdialog.xml：Dialog布局文件
	
	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <TextView 
	        android:id="@+id/tvId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:text="是否退出"
	        android:textColor="#F00"/>
	    <Button
	        android:id="@+id/btnId"
	        android:layout_below="@id/tvId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:layout_margin="10dp"
	        android:text="确定" />
	</RelativeLayout>

mainActivity中的onKeyDown方法更新直接实例化显示

	ExitDialogFragment ef=new ExitDialogFragment();
	ef.show(getFragmentManager(), "exitdialog");

ExitDialogFragment.java

设置标题等信息需要在onStart()初始化时间来调用，因为activity调用show()方法后才会显示调用其中的Fragment生命周期；

	public class ExitDialogFragment extends DialogFragment implements View.OnClickListener{
		private Button btn;
		//只能在初始化时候设置dialog标题
		@Override
		public void onStart() {
			super.onStart();
			if(getDialog()!=null)
				getDialog().setTitle("标题");
		}
		
		//给对话框实例化
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) {
			View view=inflater.inflate(R.layout.fragment_exitdialog, null);
			btn=(Button) view.findViewById(R.id.btnId);
			btn.setOnClickListener(this);
			return view;
		}
	
		@Override
		public void onClick(View v) {
			getActivity().finish();
		}
	}


![android_fragment14.png]({{site.baseurl}}/public/img/android_fragment14.png)


### ListFragment：列表对话框碎片(Fragment10)

实现ListFragment接口 内部已经创建了ListView列表，使用setListAdapter(adapter)来配置适配器，直接覆写onCreate方法后，基本上和普通的实现一样

PersonFragment.java：通过setListAdapter()：实现设置内置的ListView列表；

	public class PersonFragment extends ListFragment {
		private List<String> datas;
		private ArrayAdapter<String> adapter;
		
		@Override
		public void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			datas=new ArrayList<String>();
			adapter=new ArrayAdapter<String>(getActivity().getApplicationContext(), R.layout.item,datas);
		}
		
		@Override
		public void onActivityCreated(Bundle savedInstanceState) {
			super.onActivityCreated(savedInstanceState);
			for(int i=0;i<50;i++) datas.add("Person -> "+i);
			setListAdapter(adapter);
		}
		
		@Override
		public void onListItemClick(ListView l, View v, int position, long id){
			Toast.makeText(getActivity(),datas.get(position),1).show();
		}
	}

activity_main.xml：

	<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
	    xmlns:tools="http://schemas.android.com/tools"
	    android:layout_width="match_parent"
	    android:layout_height="match_parent"
	    tools:context=".MainActivity" >
	    <Button
	        android:id="@+id/btnId"
	        android:layout_width="wrap_content"
	        android:layout_height="wrap_content"
	        android:onClick="showList"
	        android:text="显示ListFragment列表" />
	    <FrameLayout
	        android:id="@+id/listFragId"
	        android:layout_width="fill_parent"
	        android:layout_height="fill_parent"
	        android:layout_below="@id/btnId" />
	</RelativeLayout>

MainActivity.java：

	public class MainActivity extends Activity {
		@Override
		protected void onCreate(Bundle savedInstanceState) {
			super.onCreate(savedInstanceState);
			setContentView(R.layout.activity_main);
		}
		
		public void showList(View view){
			getFragmentManager().beginTransaction().replace(R.id.listFragId, new PersonFragment()).commit();
		}
	}


![android_fragment15.png]({{site.baseurl}}/public/img/android_fragment15.png)

