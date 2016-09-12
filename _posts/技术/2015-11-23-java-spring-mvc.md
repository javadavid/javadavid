---
layout: post
title:  "java Spring MVC"
date: 2015/11/23 17:11:52 
categories:
- 技术
tags:
- 框架 
---

### 首先Struts和Spring的MVC比较

![Struts](http://img.my.csdn.net/uploads/201211/29/1354171583_5590.png)

1. 前台请求调用 通过XML中请求的文件对应mapping去请求相应的class方法。（其中要经过Filter过滤器和拦截器） 
2. 通过请求的参数，在方法中实现逻辑，产生结果，然后再通过mapping forward在struts.xml找到所需要返回的路径
3. 结果再经过过滤器返回给用户。

![Spring](http://sishuok.com/forum/upload/2012/7/14/529024df9d2b0d1e62d8054a86d866c9__1.JPG)

1. 用户请求 到前端控制器（通过servlet实现过滤），前端控制器判断交给那个页面控制器来处理
2. 页面控制器通过参数，在spring配置文件中找到相关的对象控制器，进行调用处理。最后返回一个ModelAndView的对象给前端控制器（其中包含了返回的对象和返回的地址View）
3. 前端控制器回收后进行视图的渲染，返回给用户

区别：
在于Struts控制器在Action类中完成，而Spring的是在前端的分发逻辑调用。


### 简单的 Spring MVC的框架控制（事例）


web.xml：需要配置相应的servlet，通过DispatcherServlet过滤，启动入口

	<servlet>
		<servlet-name>springMVC</servlet-name>
		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
		<init-param>
			<param-name>contextConfigLocation</param-name>
			<param-value>classpath*:config/springMVC-servlet.xml</param-value>
		</init-param>
	</servlet>
	<servlet-mapping>
		<servlet-name>springMVC</servlet-name>
		<url-pattern>/</url-pattern>
	</servlet-mapping>



springMVC-servlet（文件名称需要根据servlet名称命名），其中配置文件需要注册Bean和声明文件路径和返回后缀名

	
	<!-- 声明文件夹路径和后缀名 -->
	<bean id="viewResolver" class="org.springframework.web.servlet.view.InternalResourceViewResolver">  
        <property name="prefix" value="/"></property>
        <property name="suffix" value=".jsp"></property>  
    </bean>
    
    <!-- 声明注册Bean -->
    <bean name="/index" class="org.xh.spring.demo.HelloWorldController"></bean>

HelloWorldController类

	public class HelloWorldController implements Controller {
		@Override
		public ModelAndView handleRequest(HttpServletRequest req, HttpServletResponse resp) throws Exception {
			System.out.println("-- invoke HelloWorldController --");
			String str="Hello world";
			return new ModelAndView("/index","result",str);
		}
	}

如图显示

![j2ee_spring_mvc_01.PNG]({{site.baseurl}}/public/img/j2ee_spring_mvc_01.png)



### 注解方式实现MVC控制器

WEB.XML:配置配置 

	<!-- 配置spring启动listener入口 -->  
	<listener>
		<listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>  
	</listener>
	
	<context-param>
		<param-name>contextConfigLocation</param-name>
		<!-- 存放相关的Bean文件 -->
		<param-value>classpath*:config/springMVC-core.xml</param-value>
	</context-param>
	<servlet>
		<servlet-name>springMVC</servlet-name>
		<servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
		<init-param>
			<param-name>contextConfigLocation</param-name>
			<!--  -->
			<param-value>classpath*:config/springMVC-servlet.xml</param-value>
		</init-param>
	</servlet>
	<servlet-mapping>
		<servlet-name>springMVC</servlet-name>
		<url-pattern>/</url-pattern>
	</servlet-mapping>

	<!-- 过滤字符编码 -->
	<filter>
		<filter-name>encodingFilter</filter-name>
		<filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
		<init-param>
			<param-name>encoding</param-name>
			<param-value>UTF-8</param-value>
		</init-param>
		<init-param>
			<param-name>forceEncoding</param-name>
			<param-value>true</param-value>
		</init-param>
	</filter>
	<!-- encoding filter for jsp page -->
	<filter-mapping>
		<filter-name>encodingFilter</filter-name>
		<url-pattern>/*</url-pattern>
	</filter-mapping>

启动顺序：

第一：context-param	初始化参数

第二：Listerer 启动Spring监听操作

第三：Filter	启动编码过滤

第四：servlet 启动SpringMVC


springMVC-core.xml：声明Bean
    
	<!-- 声明注册Bean -->
    <bean id="springManager" class="org.xh.spring.demo.SpringManager"></bean>

springMVC-servlet.xml:声明环境变量
	
		<beans xmlns="http://www.springframework.org/schema/beans"    
			 xmlns:context="http://www.springframework.org/schema/context"    
			 xmlns:p="http://www.springframework.org/schema/p"    
			 xmlns:mvc="http://www.springframework.org/schema/mvc"    
			 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"    
			 xsi:schemaLocation="http://www.springframework.org/schema/beans    
		      http://www.springframework.org/schema/beans/spring-beans-3.0.xsd    
		      http://www.springframework.org/schema/context    
		      http://www.springframework.org/schema/context/spring-context.xsd    
		      http://www.springframework.org/schema/mvc    
		      http://www.springframework.org/schema/mvc/spring-mvc-3.0.xsd">  
	    <!-- 注解扫描包 -->  
	    <context:component-scan base-package="org.xh.spring.demo" />  
	    <!-- 开启注解 -->  
	      
	    <mvc:annotation-driven/>  
	      
	    <!-- 
	    <bean class="org.springframework.web.servlet.mvc.annotation.AnnotationMethodHandlerAdapter" />  
	    <bean class="org.springframework.web.servlet.mvc.annotation.DefaultAnnotationHandlerMapping"></bean>
	    -->  
	    <!-- 静态资源访问 -->  
	    <!--
	    <mvc:resources location="/img/" mapping="/img/**"/>    
	    <mvc:resources location="/js/" mapping="/js/**"/>     
	    -->
	    
	    <bean id="viewResolver" class="org.springframework.web.servlet.view.InternalResourceViewResolver">  
	        <property name="prefix" value="/"></property>  
	        <property name="suffix" value=".jsp"></property>  
	    </bean>  
	     <!-- 文件上传大小的限制和编码缓存-->
	    <bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver">  
	          <property name="defaultEncoding" value="utf-8" />  
	          <property name="maxUploadSize" value="10485760000" />  
	          <property name="maxInMemorySize" value="40960" />  
	    </bean>  
	 </beans>

ISpring.java/SpringManager.java：声明和实现接口

	public interface ISpring {
		public String get();
	}
	
	public class SpringManager implements ISpring {
		@Override
		public String get() {
			System.out.println("-- SpringManager --");
			return "this is SpringManager";
		}
	}

SpringController.java：注释声明控制层
	
	@Controller
	@RequestMapping("/SpringController")
	public class SpringController {
		//通过注释注入springManager Bean
		@Resource(name="springManager")
		private ISpring springManager;
		
		//通过 RequestMapping 设置映射地址 
		@RequestMapping("/get")
		public String get(){
			System.out.println("-- SpringController --" + springManager.get());
			return "/index";
		}
	}

- @Controller:声明控制层
- @RequestMapping:声明用户URL地址映射路径，可以用在方法和类上面

**注意：**return "/index":是访问路径的映射的JSP文件;

实现效果：
![j2ee_spring_mvc_02]({{site.baseurl}}/public/img/j2ee_spring_mvc_02.png)


参考博客  [地址](http://blog.csdn.net/lishehe/article/details/38355757)


