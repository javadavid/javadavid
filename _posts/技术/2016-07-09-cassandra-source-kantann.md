---
layout: post
title:  "Cassandra 源码"
date: 2016/7/9 14:55:09 
categories:
- 技术
tags:
- 数据存储 
---


这里用2.2.2 版本为例子；

### Cassandra 启动

入口：org.apache.cassandra.service.CassandraDaemon

static静态块：添加使用logback-metrics（具体可以查看metrics监控的用法）来监控jvm的信息，初始化Log日志；

	public void activate()
    {
        String pidFile = System.getProperty("cassandra-pidfile");
		//Windows环境；
        if (FBUtilities.isWindows())
        {
			//设置window本地时间的延迟（这里会调用native本地的winmm.dll），然后去设置调用。并且内部读取配置文件
            WindowsTimer.startTimerPeriod(DatabaseDescriptor.getWindowsTimerInterval());
        }
        try
        {
            try
            {
				//在jmx中注册NativeAccess的实例。
                MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
                mbs.registerMBean(new StandardMBean(new NativeAccess(), NativeAccessMBean.class), new ObjectName(MBEAN_NAME));
            }
            catch (Exception e)
            {
                logger.error("error registering MBean {}", MBEAN_NAME, e);
                //Allow the server to start even if the bean can't be registered
            }

            try {
				//这里是一个空的方法；用来初始化static静态块的config配置文件。（如第一次window系统初始化，这里就不需要了）
				DatabaseDescriptor.forceStaticInitialization();
            } catch (ExceptionInInitializerError e) {
                throw e.getCause();
            }
			//初始化程序
            setup();

            if (pidFile != null)
            {
                new File(pidFile).deleteOnExit();
            }
			//后台启动的输出参数
            if (System.getProperty("cassandra-foreground") == null)
            {
                System.out.close();
                System.err.close();
            }
			//启动程序
            start();
        }
        catch (Throwable e)
        {
            code...
        }
    }


- 配置文件读取DatabaseDescriptor

		static
	    {
	        try
	        {	
				//如果是安静模式，则启用本地未配置的Config（会清空配置），否则使用的yaml配置。默认的是false
	            if (Config.isClientMode())
	            {
	                conf = new Config();
	            }
	            else
	            {	
					//读取yaml并且应用到Config中。
	                applyConfig(loadConfig());
	            }
	        }
	        catch (Exception e)
	        {
	            throw new ExceptionInInitializerError(e);
	        }
	    }

	- applyConfig(loadConfig())：读取并且检查
		
			public static Config loadConfig() throws ConfigurationException
		    {
		        String loaderClass = System.getProperty("cassandra.config.loader");
		        ConfigurationLoader loader = loaderClass == null
		                                   ? new YamlConfigurationLoader()
		                                   : FBUtilities.<ConfigurationLoader>construct(loaderClass, "configuration loading");
				//根据ConfigLoader 载入默认的 yaml 配置 验证、并且反射属性到本地config私有变量中
		        return loader.loadConfig();
		    }



		- 验证参数：（同步类型，磁盘访问方式，Authentication权限）
			- commitlog_sync:commit_Log 的 periodic/同步、batch/异步
			- commitlog_sync_period_in_ms/commitlog_sync_period_in_ms：同步的时间间隔，两个时间的优先级根据同步异步判断；
			- disk_access_mode：磁盘访问模式，默认是auto（根据JDK的多少位判断使用mmap或者standard方式。），另外还有一种是mmap_index_only
			- Authentication权限：实例化authenticator/authorizer（AllowAllAuthenticator:设置密码无效/PasswordAuthenticator：设置需要使用密码）
			- internode_authenticator：peer节点访问权限的控制
			- partitioner：cluster的数据分配策略
			- 后面等等。。。
			- （hash的算法设置[用来检测数据的分布规则]、故障检测、线程池、内存的堆栈空间设置、snitch设置、Scheduler、默认keyspace data/commit_log/saved_caches/存放的路径 和默认大小的设定 、seed节点等）


- snitch选择器：用来选择更好的路由节点，默认的是SimpleSnitch，返回datacenter1。EndPointSnitch：则是根据节点的网络情况选择然后比较。默认都使用DynamicEndpointSnitch封装，然后比较俩节点的名称。

		if (conf.endpoint_snitch == null)
        {
            throw new ConfigurationException("Missing endpoint_snitch directive", false);
        }
        snitch = createEndpointSnitch(conf.endpoint_snitch);
        EndpointSnitchInfo.create();

        localDC = snitch.getDatacenter(FBUtilities.getBroadcastAddress());
		// 创建寻找节点的比较器的规则（默认采取两次对节点的寻址，然后比较名称）
        localComparator = new Comparator<InetAddress>()
        {
            public int compare(InetAddress endpoint1, InetAddress endpoint2)
            {
                boolean local1 = localDC.equals(snitch.getDatacenter(endpoint1));
                boolean local2 = localDC.equals(snitch.getDatacenter(endpoint2));
                if (local1 && !local2)
                    return -1;
                if (local2 && !local1)
                    return 1;
                return 0;
            }
        };

- setup()：方法

		protected void setup()
	    {
	        // window下面cassandra根据目录下面的.toDelete文件内容删除 失败的快照
	        if (FBUtilities.isWindows())
	            WindowsFailedSnapshotTracker.deleteOldSnapshots();
			//打印主机的一些配置日志信息（hostname、jvm、heap size、jmx的bean pool、classpath的信息）
	        logSystemInfo();
			//linux下面，执行本地native方法，来锁住内存空间（放置内存空间提交到swap区域，来提高数据访问的效率）
	        CLibrary.tryMlockall();
	
	        try
	        {
				//验证启动信息（启动时间、JMX端口状态[使用的是cassandra-env.sh启动的]、JVM虚拟机的类型、本地native库的状态、通过Sigar收集系统信息并且设置标记、数据存放目录的访问权限、sstable的格式检查[根据文件后缀和验证数据的版本来对比？]、system keyspace的状态检查[对下面的table 封装到CFMetaData，然后对其清理和重建索引或者初始化的操作和创建表。另外会对他的表空间进行临时查询操作验证是否执行正常]）
	            startupChecks.verify();
	        }
	        catch (StartupException e)
	        {
	            exitOrFail(e.returnCode, e.getMessage(), e.getCause());
	        }
	
	        try
	        {
				//比system.local中较系统版本库 和 系统property配置文件中的版本的对比；如果在升级的时候后 不匹配的快照将其备份。 
	            SystemKeyspace.snapshotOnVersionChange();
	        }
	        catch (IOException e)
	        {
	            exitOrFail(3, e.getMessage(), e.getCause());
	        }
			//尝试注册初始化JMX监控
	        maybeInitJmx();
			//设置当前守护线程的未捕获异常的默认处理方式
	        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler()
	        {
	            public void uncaughtException(Thread t, Throwable e)
	            {
	                StorageMetrics.exceptions.inc();
	                logger.error("Exception in thread {}", t, e);
	                Tracing.trace("Exception in thread {}", t, e);
	                for (Throwable e2 = e; e2 != null; e2 = e2.getCause())
	                {
	                    JVMStabilityInspector.inspectThrowable(e2);
	
	                    if (e2 instanceof FSError)
	                    {
	                        if (e2 != e) // make sure FSError gets logged exactly once.
	                            logger.error("Exception in thread {}", t, e2);
	                        FileUtils.handleFSError((FSError) e2);
	                    }
	
	                    if (e2 instanceof CorruptSSTableException)
	                    {
	                        if (e2 != e)
	                            logger.error("Exception in thread " + t, e2);
	                        FileUtils.handleCorruptSSTable((CorruptSSTableException) e2);
	                    }
	                }
	            }
	        });
	
	        // 这个地方会读取system.schema_keyspaces中的表（其中存储的是每个keyspace的信息[持久化、存储策略、复制因子]）、system.schema_columnfamilies存储了表的一些property信息、另外还有system.schema_usertypes表，储存了一些表空间访问权限。根据三张表的封装成List<KSMetaData>，然后load其中的数据，封装成Schema。（此时只有system和commitLog）
	        Schema.instance.loadFromDisk();
	
	        //从system.compactions_in_progress中取得没有压缩完成的空间信息，返回组合成一个KS/CF的键值对和sstable（set<int>）[恢复字节内容]和ID的键值对
	        Map<Pair<String, String>, Map<Integer, UUID>> unfinishedCompactions = SystemKeyspace.getUnfinishedCompactions();
	        for (Pair<String, String> kscf : unfinishedCompactions.keySet())
	        {
	            CFMetaData cfm = Schema.instance.getCFMetaData(kscf.left, kscf.right);
	            //存在CF的时候
	            if (cfm != null)
	                //对数据恢复，这里面实际上是一个反序列化的过程
					ColumnFamilyStore.removeUnfinishedCompactionLeftovers(cfm, unfinishedCompactions.get(kscf));
	        }
			//对压缩的数据碎片数据进行清理
	        SystemKeyspace.discardCompactionsInProgress();
	
	        // clean up debris in the rest of the keyspaces
	        for (String keyspaceName : Schema.instance.getKeyspaces())
	        {
	            // Skip system as we've already cleaned it
	            if (keyspaceName.equals(SystemKeyspace.NAME))
	                continue;
	
	            for (CFMetaData cfm : Schema.instance.getKeyspaceMetaData(keyspaceName).values())
	                ColumnFamilyStore.scrubDataDirectories(cfm);
	        }
	
	        Keyspace.setInitialized();
	        // initialize keyspaces
	        for (String keyspaceName : Schema.instance.getKeyspaces())
	        {
	            if (logger.isDebugEnabled())
	                logger.debug("opening keyspace {}", keyspaceName);
	            // disable auto compaction until commit log replay ends
	            for (ColumnFamilyStore cfs : Keyspace.open(keyspaceName).getColumnFamilyStores())
	            {
	                for (ColumnFamilyStore store : cfs.concatWithIndexes())
	                {
	                    store.disableAutoCompaction();
	                }
	            }
	        }
	
	
	        try
	        {
	            loadRowAndKeyCacheAsync().get();
	        }
	        catch (Throwable t)
	        {
	            JVMStabilityInspector.inspectThrowable(t);
	            logger.warn("Error loading key or row cache", t);
	        }
	
	        try
	        {
	            GCInspector.register();
	        }
	        catch (Throwable t)
	        {
	            JVMStabilityInspector.inspectThrowable(t);
	            logger.warn("Unable to start GCInspector (currently only supported on the Sun JVM)");
	        }
	
	        // replay the log if necessary
	        try
	        {
	            CommitLog.instance.recover();
	        }
	        catch (IOException e)
	        {
	            throw new RuntimeException(e);
	        }
	
	        // enable auto compaction
	        for (Keyspace keyspace : Keyspace.all())
	        {
	            for (ColumnFamilyStore cfs : keyspace.getColumnFamilyStores())
	            {
	                for (final ColumnFamilyStore store : cfs.concatWithIndexes())
	                {
	                    if (store.getCompactionStrategy().shouldBeEnabled())
	                        store.enableAutoCompaction();
	                }
	            }
	        }
	
	        SystemKeyspace.finishStartup();
	
	        // start server internals
	        StorageService.instance.registerDaemon(this);
	        try
	        {
	            StorageService.instance.initServer();
	        }
	        catch (ConfigurationException e)
	        {
	            System.err.println(e.getMessage() + "\nFatal configuration error; unable to start server.  See log for stacktrace.");
	            exitOrFail(1, "Fatal configuration error", e);
	        }
	
	        Mx4jTool.maybeLoad();
	
	        // Metrics
	        String metricsReporterConfigFile = System.getProperty("cassandra.metricsReporterConfigFile");
	        if (metricsReporterConfigFile != null)
	        {
	            logger.info("Trying to load metrics-reporter-config from file: {}", metricsReporterConfigFile);
	            try
	            {
	                String reportFileLocation = CassandraDaemon.class.getClassLoader().getResource(metricsReporterConfigFile).getFile();
	                ReporterConfig.loadFromFile(reportFileLocation).enableAll(CassandraMetricsRegistry.Metrics);
	            }
	            catch (Exception e)
	            {
	                logger.warn("Failed to load metrics-reporter-config, metric sinks will not be activated", e);
	            }
	        }
	
	        if (!FBUtilities.getBroadcastAddress().equals(InetAddress.getLoopbackAddress()))
	            waitForGossipToSettle();
	
	        // schedule periodic background compaction task submission. this is simply a backstop against compactions stalling
	        // due to scheduling errors or race conditions
	        ScheduledExecutors.optionalTasks.scheduleWithFixedDelay(ColumnFamilyStore.getBackgroundCompactionTaskSubmitter(), 5, 1, TimeUnit.MINUTES);
	
	        // schedule periodic dumps of table size estimates into SystemKeyspace.SIZE_ESTIMATES_CF
	        // set cassandra.size_recorder_interval to 0 to disable
	        int sizeRecorderInterval = Integer.getInteger("cassandra.size_recorder_interval", 5 * 60);
	        if (sizeRecorderInterval > 0)
	            ScheduledExecutors.optionalTasks.scheduleWithFixedDelay(SizeEstimatesRecorder.instance, 30, sizeRecorderInterval, TimeUnit.SECONDS);
	
	        // Thrift
	        InetAddress rpcAddr = DatabaseDescriptor.getRpcAddress();
	        int rpcPort = DatabaseDescriptor.getRpcPort();
	        int listenBacklog = DatabaseDescriptor.getRpcListenBacklog();
	        thriftServer = new ThriftServer(rpcAddr, rpcPort, listenBacklog);
	
	        // Native transport
	        InetAddress nativeAddr = DatabaseDescriptor.getRpcAddress();
	        int nativePort = DatabaseDescriptor.getNativeTransportPort();
	        nativeServer = new org.apache.cassandra.transport.Server(nativeAddr, nativePort);
	
	        completeSetup();
	    }



（待更）