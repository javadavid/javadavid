---
layout: post
title:  "Spring MVC 分析"
date: 2016/6/29 17:31:52 
categories:
- 技术
tags:
- 框架
---

springMVC整合了前后端的各种数据处理的框架。现在看看其内部的启动过程和实现；这里以4.1.1.RELEASE版本来做讲解；


### Spring容器
org.springframework.web.context.ContextLoaderListener：spring容器监听入口

	public class ContextLoaderListener extends ContextLoader implements ServletContextListener {
		//根据sevlet 初始化spring容器
		@Override
		public void contextInitialized(ServletContextEvent event) {
			initWebApplicationContext(event.getServletContext());
		}
		//销毁容器
		@Override
		public void contextDestroyed(ServletContextEvent event) {
			closeWebApplicationContext(event.getServletContext());
			ContextCleanupListener.cleanupAttributes(event.getServletContext());
		}
	}

initWebApplicationContext ： 根据servlet context 初始化 spring 容器

	public WebApplicationContext initWebApplicationContext(ServletContext servletContext) {
		//启动时候判断是否已经启动了sevlet。判断标识是org.springframework.web.context.WebApplicationContext.ROOT（锁）
		if (servletContext.getAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE) != null) {
			throw new IllegalStateException(
					"Cannot initialize context because there is already a root application context present - " +
					"check whether you have multiple ContextLoader* definitions in your web.xml!");
		}
		//通过反射调用那种日志。默认包装的org.slf4j.Logger
		Log logger = LogFactory.getLog(ContextLoader.class);
		servletContext.log("Initializing Spring root WebApplicationContext");
		//是否使用当前日志输出到控制台
		if (logger.isInfoEnabled()) {
			logger.info("Root WebApplicationContext: initialization started");
		}
		long startTime = System.currentTimeMillis();

		try {
			//内部通过构造反射注入实现 对象实例化 context 对象
			if (this.context == null) {
				//创建WebContext
				this.context = createWebApplicationContext(servletContext);
			}
			if (this.context instanceof ConfigurableWebApplicationContext) {
				ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) this.context;
				//原子操作查看web容器是否是激活状态
				if (!cwac.isActive()) {
					//判断上级是否存在父容器，并且设置上去。如需要共享配置的时候；
					if (cwac.getParent() == null) {
						ApplicationContext parent = loadParentContext(servletContext);
						cwac.setParent(parent);
					}
				//给子配置文件设置一个ID，载入容器中的contextConfigLocation、并且实例化bean到全局的webContext中；
				configureAndRefreshWebApplicationContext(cwac, servletContext);
				}
			}
			//设置锁标识；
			servletContext.setAttribute(WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, this.context);
			//将当前的上下文加入到 webcontextLoader中；
			ClassLoader ccl = Thread.currentThread().getContextClassLoader();
			if (ccl == ContextLoader.class.getClassLoader()) {
				//保存context对象到本地对象
				currentContext = this.context;
			}
			else if (ccl != null) {
				currentContextPerThread.put(ccl, this.context);
			}

			if (logger.isDebugEnabled()) {
				logger.debug("Published root WebApplicationContext as ServletContext attribute with name [" +
						WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE + "]");
			}
			if (logger.isInfoEnabled()) {
				long elapsedTime = System.currentTimeMillis() - startTime;
				logger.info("Root WebApplicationContext: initialization completed in " + elapsedTime + " ms");
			}
			return this.context;
		}
		code ....
	}

createWebApplicationContext()，一路点进去，determineContextClass方法 反射接口的实现，通过contextClass判断是其他容器或者web容器，最后返回进行反射，然后实例化context对象
	
	protected Class<?> determineContextClass(ServletContext servletContext) {
		//按照初始化的 contextClass 参数初始化反射哪个实例化对象
		String contextClassName = servletContext.getInitParameter(CONTEXT_CLASS_PARAM);
		if (contextClassName != null) {
			try {
				return ClassUtils.forName(contextClassName, ClassUtils.getDefaultClassLoader());
			}
			catch (ClassNotFoundException ex) {
				throw new ApplicationContextException(
						"Failed to load custom context class [" + contextClassName + "]", ex);
			}
		}
		else {
			//否则在 静态化实例化ContextLoader.properties 的Properties defaultStrategies中取得默认的 org.springframework.web.context.support.XmlWebApplicationContext实现
			contextClassName = defaultStrategies.getProperty(WebApplicationContext.class.getName());
			try {
				//反射对象
				return ClassUtils.forName(contextClassName, ContextLoader.class.getClassLoader());
			}
			catch (ClassNotFoundException ex) {
				throw new ApplicationContextException(
						"Failed to load default context class [" + contextClassName + "]", ex);
			}
		}
	}


### Sevelet容器

org.springframework.web.servlet.DispatcherServlet：属性文件，读取接口的反射类

	static {
		//读取 配置DispatcherServlet.properties 文件，里面是默认对相应接口的实现
		try {
			ClassPathResource resource = new ClassPathResource(DEFAULT_STRATEGIES_PATH, DispatcherServlet.class);
			defaultStrategies = PropertiesLoaderUtils.loadProperties(resource);
		}
		catch (IOException ex) {
			throw new IllegalStateException("Could not load 'DispatcherServlet.properties': " + ex.getMessage());
		}
	}

- LocaleResolver：解析和设置本地的地区语言设置，国际化的支持
- ThemeResolver：解析路径下面的默认的主题设置，css样式的支持
- HandlerMapping：对XML（BeanNameUrlHandlerMapping）中和Annotation（DefaultAnnotationHandlerMapping）中的request跳转路径的mapping的处理
- HandlerAdapter：对返回的跳转路径的处理
	- HttpRequestHandlerAdapter：对Http的请求的返回处理，return null
	- SimpleControllerHandlerAdapter：对MVC请求的返回处理，return ModelAndView
	- AnnotationMethodHandlerAdapter：使用Annotation对MVC请求的返回处理，return ModelAndView
- HandlerExceptionResolver：
- RequestToViewNameTranslator：
- ViewResolver：
- FlashMapManager：


初始化Servlet容器 HttpServletBean.init()：

	@Override
	public final void init() throws ServletException {
		if (logger.isDebugEnabled()) {
			logger.debug("Initializing servlet '" + getServletName() + "'");
		}

		try {
			//创建一个默认 存放 servlet 中的配置属性的参数 （并且判断config中的必传参数）
			PropertyValues pvs = new ServletConfigPropertyValues(getServletConfig(), this.requiredProperties);
			//返回一个本类的bean的包装信息
			BeanWrapper bw = PropertyAccessorFactory.forBeanPropertyAccess(this);
			//通过ResourceLoader 注册Resource 的实现 ResourceEditor 
			ResourceLoader resourceLoader = new ServletContextResourceLoader(getServletContext());
			bw.registerCustomEditor(Resource.class, new ResourceEditor(resourceLoader, getEnvironment()));
			initBeanWrapper(bw);
			//将初始化行为包装到dispatcher bean中
			bw.setPropertyValues(pvs, true);
		}
		catch (BeansException ex) {
			logger.error("Failed to set bean properties on servlet '" + getServletName() + "'", ex);
			throw ex;
		}

		// 初始化子类的bean、
		initServletBean();

		if (logger.isDebugEnabled()) {
			logger.debug("Servlet '" + getServletName() + "' configured successfully");
		}
	}


initServletBean()：实现

	protected final void initServletBean() throws ServletException {
		getServletContext().log("Initializing Spring FrameworkServlet '" + getServletName() + "'");
		if (this.logger.isInfoEnabled()) {
			this.logger.info("FrameworkServlet '" + getServletName() + "': initialization started");
		}
		long startTime = System.currentTimeMillis();

		try {
			//初始化 spring 的 context
			this.webApplicationContext = initWebApplicationContext();
			initFrameworkServlet();
		}
		catch (ServletException ex) {
			this.logger.error("Context initialization failed", ex);
			throw ex;
		}
		catch (RuntimeException ex) {
			this.logger.error("Context initialization failed", ex);
			throw ex;
		}

		if (this.logger.isInfoEnabled()) {
			long elapsedTime = System.currentTimeMillis() - startTime;
			this.logger.info("FrameworkServlet '" + getServletName() + "': initialization completed in " +
					elapsedTime + " ms");
		}
	}

initWebApplicationContext():

	protected WebApplicationContext initWebApplicationContext() {
		//取得rootContext。也就是spring在初始化的时候的context节点	
		WebApplicationContext rootContext =
					WebApplicationContextUtils.getWebApplicationContext(getServletContext());
			WebApplicationContext wac = null;
	
			if (this.webApplicationContext != null) {
				// A context instance was injected at construction time -> use it
				wac = this.webApplicationContext;
				if (wac instanceof ConfigurableWebApplicationContext) {
					ConfigurableWebApplicationContext cwac = (ConfigurableWebApplicationContext) wac;
					if (!cwac.isActive()) {
						// The context has not yet been refreshed -> provide services such as
						// setting the parent context, setting the application context id, etc
						if (cwac.getParent() == null) {
							// The context instance was injected without an explicit parent -> set
							// the root application context (if any; may be null) as the parent
							cwac.setParent(rootContext);
						}
						configureAndRefreshWebApplicationContext(cwac);
					}
				}
			}
			if (wac == null) {
				// 查找上下文 注入一个构造，如果不存在。查找一个注册过的servletContext，如果在没有，则将其认为是parent Context，然后放入其中
				wac = findWebApplicationContext();
			}
			if (wac == null) {
				//根据root context 创建一个本地的context环境；将servlet载入其中；
				wac = createWebApplicationContext(rootContext);
			}
	
			if (!this.refreshEventReceived) {
				// Either the context is not a ConfigurableApplicationContext with refresh
				// support or the context injected at construction time had already been
				// refreshed -> trigger initial onRefresh manually here.
				onRefresh(wac);
			}
	
			if (this.publishContext) {
				// Publish the context as a servlet context attribute.
				String attrName = getServletContextAttributeName();
				getServletContext().setAttribute(attrName, wac);
				if (this.logger.isDebugEnabled()) {
					this.logger.debug("Published WebApplicationContext of servlet '" + getServletName() +
							"' as ServletContext attribute with name [" + attrName + "]");
				}
			}
	
			return wac;
		}


createWebApplicationContext(rootContext)：servlet添加到 取得web的root容器 里面，配置更新操作

	protected WebApplicationContext createWebApplicationContext(ApplicationContext parent) {
		//取得context实例类型：XmlWebApplicationContext
		Class<?> contextClass = getContextClass();
		if (this.logger.isDebugEnabled()) {
			this.logger.debug("Servlet with name '" + getServletName() +
					"' will try to create custom WebApplicationContext context of class '" +
					contextClass.getName() + "'" + ", using parent context [" + parent + "]");
		}
		if (!ConfigurableWebApplicationContext.class.isAssignableFrom(contextClass)) {
			throw new ApplicationContextException(
					"Fatal initialization error in servlet with name '" + getServletName() +
					"': custom WebApplicationContext class [" + contextClass.getName() +
					"] is not of type ConfigurableWebApplicationContext");
		}
		//对接口反射实例化
		ConfigurableWebApplicationContext wac =
				(ConfigurableWebApplicationContext) BeanUtils.instantiateClass(contextClass);
		//设置其环境；
		wac.setEnvironment(getEnvironment());
		//设置rootContext
		wac.setParent(parent);
		//context的配置
		wac.setConfigLocation(getContextConfigLocation());
		
		configureAndRefreshWebApplicationContext(wac);

		return wac;
	}

configureAndRefreshWebApplicationContext(was):重新载入启动context

	protected void configureAndRefreshWebApplicationContext(ConfigurableWebApplicationContext wac) {
		if (ObjectUtils.identityToString(wac).equals(wac.getId())) {
			//给子容器设置一个ID编号；
			if (this.contextId != null) {
				wac.setId(this.contextId);
			}
			else {
				(ConfigurableWebApplicationContext.APPLICATION_CONTEXT_ID_PREFIX +
						ObjectUtils.getDisplayString(getServletContext().getContextPath()) + "/" + getServletName());
			}
		}
		//将子容器上下文 注入到root容器；
		wac.setServletContext(getServletContext());
		//将配置注入到 root容器 
		wac.setServletConfig(getServletConfig());
		//给子容器设置一个名称；
		wac.setNamespace(getNamespace());
		//给webcontenxt添加一个监听，当application down掉或者关闭的时候
		wac.addApplicationListener(new SourceFilteringListener(wac, new ContextRefreshListener()));

		// 替换 servlet 初始化参数（servletContextInitParams）、确保替换属性 在运行中或者初始化之前。
		ConfigurableEnvironment env = wac.getEnvironment();
		if (env instanceof ConfigurableWebEnvironment) {
			((ConfigurableWebEnvironment) env).initPropertySources(getServletContext(), getServletConfig());
		}

		postProcessWebApplicationContext(wac);
		applyInitializers(wac);
		wac.refresh();
	}

wac.refresh()：里面有点复杂、主要是负责初始化IOC容器的初始化；

onRefresh(was)： 将初始载入的 static 初始化 配置文件中的接口实现，设置默认的解析器的行为

	protected void initStrategies(ApplicationContext context) {
		initMultipartResolver(context);
		initLocaleResolver(context);
		initThemeResolver(context);
		initHandlerMappings(context);
		initHandlerAdapters(context);
		initHandlerExceptionResolvers(context);
		initRequestToViewNameTranslator(context);
		initViewResolvers(context);
		initFlashMapManager(context);
	}


总结：httpServlet（init） - httpSeveletBean ( initServletBean ) - FrameworkServelt ( initWebApplicationContext ) - refresh（IOC注入）

ContextLoaderListener：对spring的配置文件载入

DispatcherServlet：对Context上下文的载入，最后塞入到spring容器中


### SpringMVC的请求处理

入口 DispatcherServlet processDispatchResult，用来处理异常和View的封装

	private void processDispatchResult(HttpServletRequest request, HttpServletResponse response,
			HandlerExecutionChain mappedHandler, ModelAndView mv, Exception exception) throws Exception {

		boolean errorView = false;
		//处理异常；判断是系统异常还是跳转异常
		if (exception != null) {
			if (exception instanceof ModelAndViewDefiningException) {
				code...
		}

		// Did the handler return a view to render?
		if (mv != null && !mv.wasCleared()) {
			//设置本地Local、解析将ModelAndView解析成View对象（一种是存放的是引用的View对象，另外一种是存放的View的实体String名称）
			render(mv, request, response);
			if (errorView) {
				WebUtils.clearErrorRequestAttributes(request);
			}
		}
		code...
	}


resend():通过解析器解析View

	protected void render(ModelAndView mv, HttpServletRequest request, HttpServletResponse response) throws Exception {
		Locale locale = this.localeResolver.resolveLocale(request);
		response.setLocale(locale);
		View view;
		//ModelAndView中的view是否存在View的实体，还是说String名称
		if (mv.isReference()) {
			//对View对象解析
			view = resolveViewName(mv.getViewName(), mv.getModelInternal(), locale, request);
			if (view == null) {
				throw new ServletException("Could not resolve view with name '" + mv.getViewName() +
						"' in servlet with name '" + getServletName() + "'");
			}
		}
		code...
	}


resolveViewName:查找解析器解析View对象

	protected View resolveViewName(String viewName, Map<String, Object> model, Locale locale,
			HttpServletRequest request) throws Exception {
		//查找  在context中注册的bean对象的解析器 匹配后返回解析器
		for (ViewResolver viewResolver : this.viewResolvers) {
			View view = viewResolver.resolveViewName(viewName, locale);
			if (view != null) {
				return view;
			}
		}
		return null;
	}

Velocity的解析器
org.springframework.web.servlet.view.velocity.VelocityLayoutViewResolver

	public View resolveViewName(String viewName, Locale locale) throws Exception {
		if (!isCache()) {
			return createView(viewName, locale);
		}
		code...
	}



createView():分别解析对view的return路径的名称redirect、forward的处理方式


	protected View createView(String viewName, Locale locale) throws Exception {
		//判断是否支持View的解析
		if (!canHandle(viewName, locale)) {
			return null;
		}
		// Check for special "redirect:" prefix.
		if (viewName.startsWith(REDIRECT_URL_PREFIX)) {
			return code...
		}
		// Check for special "forward:" prefix.
		if (viewName.startsWith(FORWARD_URL_PREFIX)) {
			return code...
		}
		// Else fall back to superclass implementation: calling loadView.
		return super.createView(viewName, locale);
	}


进一步AbstractCachingViewResolver.createView --> UrlBasedViewResolver.loadView():这里会通过解析器对View进一步封装，设置其中的一些常用的变量属性。

	protected View loadView(String viewName, Locale locale) throws Exception {
		AbstractUrlBasedView view = buildView(viewName);
		View result = applyLifecycleMethods(viewName, view);
		return (view.checkResource(locale) ? result : null);
	}

buildView():这里才是真正的解析出了VelocityLayoutView的视图对象，然后dispatcher将其分发到前端后直接通过module完成渲染工作





