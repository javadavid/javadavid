---
layout: post
title:  "JMS（ActiveMQ） 消息队列"
date: 2016/1/14 14:53:16 
categories:
- 技术
tags:
- 框架
---

### JMS

- Java Messaging Service 消息队列
- 属于一种中间件(MOM)
- 设计根据的是消费者生产者模式
- 不需要 生产者 消费者 同时运行


### 对象模型：

- 连接工厂（ConnectionFactory）：管理员创建，绑定到连接池中，可以通过其创建JMS连接
- JSM连接（Connection）：客户端和服务端的活动连接，客户端（程序）调用工厂创建
- JMS会话（Session）：包含JMS客户端之间的会话状态，连接后（connetion.start）创建一个回话线程
- JMS接口（Destination）：通过session创建得到的一个消息管理的对象位置
- JMS生产者（Message Producer）和消费者（Message Consumer）:都是由Session创建，用于接收和发送消息
- JMS消息（Message）：用于封装传递消息对象；简单文本(TextMessage)、可序列化的对象 (ObjectMessage)、属性集合 (MapMessage)、字节流 (BytesMessage)、原始值流 (StreamMessage)


![JMS模型]({{site.baseurl}}/public/img/java_jms_module.png)

### 发送的类型

- 点对点（Point-to-Point）：一个生产者 --> 一个消费者
- 发布/订阅（Publish/Subscribe）广播：一个生产者 --> 多个消费者


### ActiveMQ

是Apache提供的开源的一个消息列表组件
apache-activemq-5.5.1下载运行服务器 管理的 连接管道的地址在conf文件中

	<transportConnectors>
	    <transportConnector name="openwire" uri="tcp://localhost:61616" discoveryUri="multicast://default"/>
	    <transportConnector name="ssl" uri="ssl://localhost:61617"/>
	    <transportConnector name="stomp" uri="stomp://localhost:61613"/>
	    <transportConnector name="xmpp" uri="xmpp://localhost:61222"/>
	</transportConnectors>

这里演示一对一的情况

![java_jms_package.png]({{site.baseurl}}/public/img/java_jms_package.png)

Sender.java：生产者

	public class Sender {
		private static final int SEND_NUM=5;
		
		public static void main(String args[]){
			//JMS工厂连接；
			ConnectionFactory connectionFactory;	
			
			//JMS连接到Provider的数据源连接
			Connection conn=null;
			
			//发送或者接收消息的线程；
			Session session ;
			
			//消息的发送的目的地
			Destination dest;
			
			//消息发送者
			MessageProducer producer;
			
			//实例化 ConnectionFactory 通过 org.apache.activemq.ActiveMQConnectionFactory   用户名 密码 地址
			connectionFactory = new ActiveMQConnectionFactory(ActiveMQConnection.DEFAULT_USER, 
								ActiveMQConnection.DEFAULT_PASSWORD,
						        "tcp://localhost:61616");
			try{
				//创建连接
				conn = connectionFactory.createConnection();
				
				conn.start();
				
				//获取连接操作
				session =conn.createSession(true, Session.AUTO_ACKNOWLEDGE);
				
				//并取服务器得一个Queue，需要在 ActivityMQ中配置一个列表
				dest= session.createQueue("FirstQueue");
				
				//通过 dest Queue取得 发送者
				producer=session.createProducer(dest);
				
				//设置发送的模式
				producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
				
				//发送数据
				sendMessage(session, producer);
	            session.commit();
				
			}catch(Exception e ){
				e.printStackTrace();
			}finally{
				if(conn!=null){
					try {
						conn.close();
					} catch (JMSException e) {
						e.printStackTrace();
					}
				}
			}
		}
	
		private static void sendMessage(Session session, MessageProducer producer) throws JMSException {
			for(int i=0;i<SEND_NUM;i++){
				//封装文本数据
				TextMessage message=session.createTextMessage(" MQ发送的消息  " +i );
				
				System.out.println( "ActiveMq 发送的消息" + i);
				
				producer.send(message);	//发送消息
			}
		}
	}

Receiver.java：消费者

	public class Receiver {
		public static void main(String args[]){
			//JMS工厂连接；
			ConnectionFactory connectionFactory;	
			
			//JMS连接到Provider的数据源连接
			Connection conn=null;
			
			//发送或者接收消息的线程；
			Session session ;
			
			//消息的接收目的地
			Destination dest;
			
			//消息接受者
			MessageConsumer consumer;
			
			//实例化 ConnectionFactory 通过 org.apache.activemq.ActiveMQConnectionFactory   用户名 密码 地址
			connectionFactory = new ActiveMQConnectionFactory(ActiveMQConnection.DEFAULT_USER, 
								ActiveMQConnection.DEFAULT_PASSWORD,
						        "tcp://localhost:61616");
			try{
				//创建连接
				conn = connectionFactory.createConnection();
				
				conn.start();
				//获取连接操作
				session =conn.createSession(false, Session.AUTO_ACKNOWLEDGE);
				
				//并取服务器得一个Queue，需要在 ActivityMQ中配置一个列表
				dest= session.createQueue("FirstQueue");
				
				//通过 dest Queue取得 接受者
				consumer=session.createConsumer(dest);
	
				//接收数据
				while (true) {
					//接收文本数据
					TextMessage message=(TextMessage) consumer.receive(50000);
					if(message!=null){
						System.out.println(" 收到消息 ：" + message.getText());
					}else{
						break;
					}
				}
			}catch(Exception e ){
				e.printStackTrace();
			}finally{
				if(conn!=null){
					try {
						conn.close();
					} catch (JMSException e) {
						e.printStackTrace();
					}
				}
			}
		}
	}

消息的发送个接收都要取得JMS管道（Destination），通过地址 传输和接收(处理)相应的队列消息（Message）

ConnectionFactory -> Connection连接后 -> Session -> Destination 和 创建生产者（MessageProducer）、消费者（MessageConsumer）

- MessageProducer 通过send传递session创建的Message
- MessageConsumer 通过receive接收消息队列

![java_jms_producer.png]({{site.baseurl}}/public/img/java_jms_producer.png)
  
![java_jms_consumer.png]({{site.baseurl}}/public/img/java_jms_consumer.png)

在服务器可以显示消息传递状态 http://localhost:8161/admin/queues.jsp

![java_jms_status]({{site.baseurl}}/public/img/java_jms_status.png)

参考

百度百科 和 http://www.cnblogs.com/xwdreamer/archive/2012/02/21/2360818.html

