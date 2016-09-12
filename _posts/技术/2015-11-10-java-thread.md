---
layout: post
title:  "java中线程的理解"
date:   2015.11.10 23:13:04 
categories:
- 技术
tags:
- Java
---
### 线程创建的方式

>java创建线程主要有2中方式：继承Thread类和实现Runnable接口
>
>第三种是使用ExecutorService、Callable、Future实现有返回结果的多线程;这几个都是Executor中的功能类  执行后返回的对象是Future类

	//实现线程类的基本构造;
	public Thread( );
	public Thread(Runnable target);
	public Thread(String name);
	public Thread(Runnable target, String name);
	public Thread(ThreadGroup group, Runnable target);
	public Thread(ThreadGroup group, String name);
	public Thread(ThreadGroup group, Runnable target, String name);
	public Thread(ThreadGroup group, Runnable target, String name, long stackSize);

### 生命周期
	// 开始线程
	publicvoid start( );
	publicvoid run( );
	// 挂起和唤醒线程
	publicvoid resume( );     // 不建议使用
	publicvoid suspend( );    // 不建议使用
	publicstaticvoid sleep(long millis);
	publicstaticvoid sleep(long millis, int nanos);
	// 终止线程
	publicvoid stop( );       // 不建议使用
	publicvoid interrupt( );
	// 得到线程状态
	publicboolean isAlive( );
	publicboolean isInterrupted( );
	publicstaticboolean interrupted( );
	// join方法
	publicvoid join( ) throws InterruptedException;

### 无返回值的创建方式	

>都需要覆盖其中的**run()**方法；并且使用**start()**来启动线程(run方法中的内容)；Thread适合创建一个,Runnable适合创建多个

#### 继承Thread

	public class Thread1 {
		public static void main(String args[]){
			Demo d=new Demo();
			d.start();
		}
	}
	class Demo extends Thread{		//继承Thread 创建线程;
		@Override
		public void run() {
			for(int i=0;i<60;i++){
				System.out.println(Thread.currentThread().getName()+"->"+i);
			}
		}
	}


	public class Thread2 {
		public static void main(String args[]){
			Demo2 d=new Demo2();
			Thread t=new Thread(d);
			t.start();
			for(int i=0;i<100;i++){
				System.out.println(Thread.currentThread().getName()+"->"+i);
			}
		}
	}
	
#### 实现接口Runnable
	
	class Demo2 implements Runnable{		//实现接口Runnable创建接口;
		@Override
		public void run() {
			for(int i=0;i<1000;i++){
				System.out.println(Thread.currentThread().getName()+"->"+i);
			}
		}
	}

### 线程的同步（关键字synchronized）

- 代码块的同步

		class Ticket implements Runnable{
			private int ticket=400;
			@Override
			public void run() {
				while (true) {
					synchronized(new Object()){		//同步代码块
						try {
							Thread.sleep(1);
						} catch (InterruptedException e) {
							e.printStackTrace();
						}
						if(ticket<0)
							break;
						System.out.println(Thread.currentThread().getName()+"-卖出-"+ticket--);
					}
				}
			}
		}



- 同步函数

		class Ticket implements Runnable{
			private int ticket=4000;
			private boolean flag=true;
			public synchronized void saleTicket(){			//同步函数;
				if(ticket>0)
					System.out.println(Thread.currentThread().getName()+"-卖出-"+ticket--);
			}
			@Override
			public void run() {
				while(flag){
					saleTicket();
					if(ticket==0){
						flag=false;
					}
				}
			}
		}

- 通过synchronized 代码块 实现取值设值得同步

		public class Thread4 {
			public static void main(String args[]){
				class Person{
					public String name;
					public String gender;
					public void set(String name, String gender) {
						this.name = name;
						this.gender = gender;
					}
					public void get(){
						System.out.println(this.name+"----"+this.gender);
					}
				};
				final Person p=new Person();
				p.set("张三", "男");
				new Thread(new Runnable() {
					@Override
					public void run() {
						int x=0;
						while(true){
							/*
							if(x==0){
								p.set("张三", "男");
							}else{
								p.set("lisi", "nv");
							}
							*/
							synchronized (p) {
								if(x==0){
									p.set("张三", "男");
								}else{
									p.set("lisi", "nv");
								}
							}
							x=(x+1)%2;
						}
					}
				}).start();;		
				new Thread(new Runnable() {
					public void run() {
						/*
						while(true){
							p.get();		//取值、设值不同步		lisi----男
						}
						*/
						while(true){
							synchronized (p) {
								p.get();	//同步对象后正常取值
							}
						}
					}
				}).start();
			}
		}

- 多线程数据共享问题

		//生产者和消费者问题；在Goods类中定义 生产和消费方法 对其取值和生产值 进行代码的同步
		public class Thread7 {
			private static boolean flags = false;
			public static void main(String[] args) {
				class Goods{
					private String name;
					private int num;
					private synchronized void produce(String name) {		//生产;
						if(flags){
							try {
								wait();
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}
						this.name=name+" 编号"+num++;
						System.out.println(Thread.currentThread().getName()+"生产了...."+this.name);
						flags=true;
						notifyAll();
					}
					private synchronized void consume() {		//消费
						if(!flags){
							try {
								wait();
							} catch (InterruptedException e) {
								e.printStackTrace();
							}
						}
						System.out.println(Thread.currentThread().getName()+"消费了******"+name);
						flags=false;
						notifyAll();
					}
				}
				final Goods g=new Goods();
				new Thread(new Runnable() {
					@Override
					public void run() {
						while(true){
							g.produce("商品");
						}
					}
				},"一号生产者").start();
				new Thread(new Runnable() {
					@Override
					public void run() {
						while(true){
							g.produce("商品");
						}
					}
				},"二号生产者").start();
				new Thread(new Runnable() {
					@Override
					public void run() {
						while(true){
							g.consume();
						}
					}
				},"一号消费者").start();
				new Thread(new Runnable() {
					@Override
					public void run() {
						while(true){
							g.consume();
						}
					}
				},"二号消费者").start();
			}
		}


### 有返回值的线程(Callable)

	//通过实现Callable接口   创建线程池后并且获取 有返回值的多个线程;
	public class Thread8 {
		public static void main(String[] args) throws InterruptedException, ExecutionException {
			System.out.println("-------线程开始执行;-------");
			long t1=System.currentTimeMillis();
			int taskSize=5;
			//创建一个线程池;
			ExecutorService pool=Executors.newFixedThreadPool(taskSize);	
			List<Future> list=new ArrayList<Future>();
			for(int i=0;i<taskSize;i++){
				//创建线程;
				Callable c=new MyCallable(i+" ");
				//执行任务并且获取对象;
				Future f=pool.submit(c);
				list.add(f);
			}
			pool.shutdown();
			for(Future f:list){
				//输出返回对象;
				System.out.println(">>>"+f.get().toString());
			}
			long t2=System.currentTimeMillis();
			System.out.println("--程序结束运行--时间:"+(t2-t1));
		}
	}
	class MyCallable implements Callable<Object>{
		private String taskNum;
		public MyCallable(String taskNum) {
			this.taskNum = taskNum;
		}
		@Override
		public Object call() throws Exception {
			System.out.println(">>>"+taskNum+"启动任务...");
			long t1=System.currentTimeMillis();
			Thread.sleep(1000);
			long t2=System.currentTimeMillis();
			System.out.println(">>>"+taskNum+"终止任务...");
			return taskNum+"任务返回运行结果,任务执行的时间是: "+(t2-t1);
		}
	}

	/*
	执行结果
	-------线程开始执行;-------
	>>>0 启动任务...
	>>>2 启动任务...
	>>>1 启动任务...
	>>>4 启动任务...
	>>>3 启动任务...
	>>>0 终止任务...
	>>>2 终止任务...
	>>>3 终止任务...
	>>>4 终止任务...
	>>>1 终止任务...
	>>>0 任务返回运行结果,任务执行的时间是: 1000
	>>>1 任务返回运行结果,任务执行的时间是: 1000
	>>>2 任务返回运行结果,任务执行的时间是: 1000
	>>>3 任务返回运行结果,任务执行的时间是: 1000
	>>>4 任务返回运行结果,任务执行的时间是: 1000
	--程序结束运行--时间:1007
	*/


代码说明:Executors下面提供了一些工厂方法

- public static ExecutorService newFixedThreadPool(int nThreads) :创建一个固定数目线程池
- public static ExecutorService newCachedThreadPool() :创建一个有缓存的线程池; 创建时候对缓存中的线程垃圾回收;
- public static ExecutorService newSingleThreadExecutor() :创建一个单线程的Executor
- public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) :创建一个有周期性的执行任务的线程池
- ExecutoreService的submit()方法接受Callable或者Runnable;返回Future结果; 结果输出get方法是同步操作; 

参考:[csdn Blog](http://blog.csdn.net/aboy123/article/details/38307539)