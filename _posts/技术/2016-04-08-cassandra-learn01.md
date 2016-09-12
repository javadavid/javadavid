---
layout: post
title:  "Cassandra 入门"
date: 2016/4/8 18:06:07 
categories:
- 技术
tags:
- 数据存储 
---

### Cassandra

是由apache的开源分布式NO_SQL网络存储服务，facebook人员开发；其结构类似于四、五维数组的结构，最根尾节点的键值对是 name - value - timestamp，并且在写入数据之前，会记录写入日志（CommitLog），按照key-value进行存放在内存；一定条件后，最后会存储在磁盘上，存放格式是SSTable。


#### 目录结构
![cassandra-dir]({{site.baseurl}}/public/img/cassandra-dir.png)

- bin：存放可执行文件，其中nodetool是用来检测集群是否合理配置，管理操作；另外还有些数据文件SSTable和JSon相互转换的脚本
- conf：包含cassandra的启动配置文件；
	- stroage-conf.xml:配置keyspace 和 列族 ，创建存储系统
	- log4j.properties:用来配置日志的等设置；
	- 另外就是一些文件就是用来鉴别权限设置；
- interface：里面文件cassandra.thrift ；另外thrift是apache的一个开源的服务调用接口，（详细可以参考http://www.ibm.com/developerworks/cn/java/j-lo-apachethrift/）
- lib：包含一些cassandra所要运行的依赖库。如：json解析相关（json-simple-1.1），另外的apache的相关开源库；
- javadoc：相关的Api说明文档

#### Windows启动服务

首先在bin目录下面有相关的启动批处理，根据系统选择不同；这里window使用shell启动。若是第一次启动需要配置JAVA_HOME环境（需要jdk1.7+）。进入bin启动`cassandra.bat`

![cassandra-shell01]({{site.baseurl}}/public/img/cassandra-shell01.png)

提示需要执行`powershell Set-ExecutionPolicy Unrestricted`，赋予shell的执行权限

在运行后。本地启动服务后如图所示：

![cassandra-shell02]({{site.baseurl}}/public/img/cassandra-shell02.png)

连接数据源：启动客户端cassandra-cli.bat；

![cassandra-shell03]({{site.baseurl}}/public/img/cassandra-shell03.png)

`?`/`help` 可以查询相关命令；

#### 服务启动初始化配置

配置文件统一放在了conf/cassandra.yaml下面 

	cluster_name：集群名称，默认 'Test Cluster'//使用show cluster name命令可以显示
	listen_address：监听的IP或者主机 默认 localhost
	commitlog_directory：commitlog的保存目录 默认保存路径$CASSANDRA_HOME/data/commitlog
	data_file_directories：数据文件保存目录，默认$CASSANDRA_HOME/data/data
	save_caches_directory：缓存存放目录
	commit_failure_policy：提交失败采取的策略 
		- die：关闭gossip、Thrift和JVM，节点被替换；
		- stop：关闭gossip和Thrift，挂载到节点，可以用jmx进行检查访问
		- stop_commit：关闭提交日志（commit log），关闭写服务，但是保存了读取的服务；
		- ignore：忽略所有的致命错误
	disk_failure_policy：磁盘错误的策略
		- die：关闭gossip、Thrift和JVM，节点被替换；
		- stop_paranoid：任何的sstable错误都关闭gossip和客户端传输
		- stop：关闭gossip和客户端传输，挂载node节点，能够通过JMX访问
		- best_effort：隔离已用的失败的磁盘空间，并且返回可使用的磁盘sstables
		- ignore：忽略致命错误，并且让提交失败；
	endpoint_snitch：定位节点的路由请求
	rpc_address：监听客户端连接地址
	seed_provider：需要联系的节点地址
	compaction_throughput_mb_per_sec：特定吞吐量下面的压缩速率
	memtable_heap_space_in_mb：最大使用的内存空间数量
	concurrent_reads/concurrent_writes：并发下面的读取/写入数量；
	incremental_backups：是否采用增量备份；
	snapshot_before_compaction：压缩前执行快照；

#### 数据模型
![](http://www.ibm.com/developerworks/cn/opensource/os-cn-cassandra/image001.gif)

概念：

1. Cluster集群：Cassandra节点实例，存放Keyspace。
2. KeySpace：存放ColumnFamily容器；相当于数据库中的Schema或者Database
3. ColumFamily：存放Column的容器；类似于Table的概念。
4. SuperColums：特使的Column，key-columns（其中包含了多个column）。
5. Columns：最基本的单位。name - value - timestamp组成。

数据操作

- 数据写入

	> 格式：set keyspace.standard[key][columns.name] = value
		
		set Keyspace1.Stamdard2['studentA']['age']='18'

- 读取数据

	> 格式：get keyspace.standard[key]
	
		get Keyspace1.Stamdard2['studentA']
		
		//默认返回第一行的数据
		(column=age,value=18,timestamp=1270694041669000)

#### CQL的配置 和 数据定义/操作语句

在CQL中是忽略大小写的，如 keyspace、column、table的名称。字段名称使用双引号括起来则是大小写敏感的

配置系统需要安装python，本地通过cmd命令 `python cqlsh` 启动 进入CQL ，help可以提供相关操作命令提示；外部连接的默认密码是 cassandra/cassandra

![cassandra-shell04]({{site.baseurl}}/public/img/cassandra-shell04.png)


1. 创建用户

		CREATE USER myusername WITH PASSWORD 'mypassword' SUPERUSER ;
	
2. 删除用户
	
		DROP USER cassandra ;


**keySpace 操作：**

- 创建keyspace

	> CREATE < keyspaceName > (if not exists) ? < identifier > WITH < propities > 
	
	- identifier：长度小于32，大小写敏感。可以使用大小写双引号表示大小写敏感；
	- propities：replication(复制策略:)、durable_writes（持久化写入conmmit log，默认是true）;

- 修改keyspace

	> ALTER KEYSPACE < keyspaceName > (if not exists) ? < identifier > WITH < propities > 

- 删除keyspace

	> DROP KEYSPACE < keyspaceName > (if exists) ? < identifier > 

- 切换keyspace 

	> USE < keyspaceName >

- 显示keyspace信息；
	
	> DESC KEYSPACE < keyspaceName >
	
	![cassandra-shell05]({{site.baseurl}}/public/img/cassandra-shell05.png)

**Table/COLUMNFAMILY的操作：**

- 创建族列
	
		CREATE TABLE < tableName >(
			columnsName type 
			... 
		) WITH < property1 > AND < proprty2 > ... ;
	
		//Example:
		create table testtable (
			columnsId int primary key,
			name text,
			age int 
		)

	- 关于< property >

		> comment ：对列族信息的描述    
		> compaction：数据压缩策略    
		> compression：数据压缩算法   
		> defalut_time_to_live：存活时间，默认是0，永久   
		> caching：设置缓存方案；   



- 显示Table详细信息，此时会显示表的默认配置property信息；
	
	> DESC < tableName >;

	![cassandra-shell06]({{site.baseurl}}/public/img/cassandra-shell06.png)
	
- 修改 

	> ALTER TABLE < tableName > < instraction >

		//1.
		ALTER TABLE testTable 
		ADD sex text;
	
		//2.
		ALTER TABLE testTable 
		WITH comment =' this is test comment '
		AND read_repair_chance = 0.2 ;

- 删除Table

	> DROP TABLE < tableName >

- 清空Table

	> TRUNCATE < tableName >

**索引Index的操作：**

- 创建第二索引

		CREATE (CUSTOM) INDEX (IF NOT EXISTS)? (< indexName >)? 
			ON < tableName > ( < index-indefier > ) 
			(USING < string > (WITH OPTIONS = < map-literal >)?)?
	
		1.
		CREATE INDEX indexName ON tableName(columnsName);

		2.
		CREATE INDEX on tableName(columnsName);

		3.
		CREATE INDEX on keySpaceName(keyName(columnsName));
		
		4.
		CREATE CUSTOM INDEX on tableName(columnsName);
		
		5.
		CREATE CUSTOM INDEX on tableName(columnsName) USING 'path.to.the.IndexClass';
		
		6.
		CREATE CUSTOM INDEX on tableName(columnsName) USING 'path.to.the.IndexClass' WITH OPTION = {'storage':'/mnt/ssd/indexes/'};

- 删除第二索引

		DROP INDEX ( IF EXISTS )?( < keyspace > ) ? < identifier >

		1.
		DROP INDEX indexName;

		2.
		DROP INDEX keySpaceName.indexName;

CQL的数据操作语句：Cassandra 2.2 开始，select和insert加入了JSON操作；

- insert

		INSERT INTO <tablename>
		  ( ( <name-list> VALUES <value-list> )
		  | ( JSON <string> ))
		  ( IF NOT EXISTS )?
		  ( USING <option> ( AND <option> )* )?


		insert into testtable ( columnsid , age, name , sex)  values ( 1,15,'zhangsan' ,'nan') USING TTL 86400;
		
		INSERT INTO NerdMovies JSON '{"movie": "Serenity", "director": "Joss Whedon", "year": 2005}'
		
- update：
		
		UPDATE < tableName >
		( USING < option > ( AND < option > )* )?
		SET columns = 'values',...
		WHERE columns = 'values' ( < condition > )
		
		UPDATE NerdMovies USING TTL 400
		SET director = 'Joss Whedon',
		    main_actor = 'Nathan Fillion',
		    year = 2005
		WHERE movie = 'Serenity';
		
		UPDATE UserActions SET total = total + 2 WHERE user = B70DE1D0-9908-4AE3-BE34-5573E5B09F14 AND action = 'click';

- delete	：必须需要where条件

		DELETE ( < selection > (',' < selection > )* )?
	 	FROM < tableName >
		( USING TIMESTAMP < integer > )?
		WHERE < where-clause >
		( IF ( EXISTS | ( < condition > ( AND < condition > )* ) ) )?

		1.用于删除整行数据
		DELETE FROM NerdMovies USING TIMESTAMP 1240003134 WHERE movie = 'Serenity';

		2.用于删除列数据中的元素
		DELETE phone FROM Users WHERE userid IN (C73DE1D3-AF08-40F3-B124-3FF3E5109F22, B70DE1D0-9908-4AE3-BE34-5573E5B09F14);


- batch
		
		BEGIN ( UNLOGGED | COUNTER ) BATCH
		( USING < option > ( AND < option > )* )?
		< modification-stmt > ( ';' < modification-stmt > )*  
		APPLY BATCH 

		BEGIN BATCH
		  INSERT INTO users (userid, password, name) VALUES ('user2', 'ch@ngem3b', 'second user');
		  UPDATE users SET password = 'ps22dhds' WHERE userid = 'user3';
		  INSERT INTO users (userid, password) VALUES ('user4', 'ch@ngem3c');
		  DELETE name FROM users WHERE userid = 'user1';
		APPLY BATCH;

- select：查询的where条件必须是索引index
		
		SELECT ( JSON )? < columnsName > 
		FROM < tableName >
		( WHERE < where-clause > )?
		( ORDER BY < order-by > )?
		( LIMIT < integer > )?
		( ALLOW FILTERING )? 


		SELECT name, occupation FROM users WHERE userid IN (199, 200, 207);

		SELECT JSON name, occupation FROM users WHERE userid = 199;
		
		SELECT name AS user_name, occupation AS user_occupation FROM users;
		
		SELECT time, value
		FROM events
		WHERE event_type = 'myEvent'
		  AND time > '2011-02-03'
		  AND time <= '2012-01-01'
		
		SELECT COUNT(*) FROM users;
		
		SELECT COUNT(*) AS user_count FROM users;

#### Java连接操作Cassandra

首先Maven依赖

	<dependency>
         <groupId>com.datastax.cassandra</groupId>
         <artifactId>cassandra-driver-core</artifactId>
         <version>2.1.5</version>
    </dependency>

测试代码

	//列出所有的节点、keyspace实例
	public class App {
		public static void main(String[] args) {
			
			//添加一个节点
			Cluster cluster = Cluster.builder().addContactPoint("localhost").build();
			
			//取得节点的数据源
			Metadata metadata = cluster.getMetadata();
	
			//输出所有的host
			for(Host host : metadata.getAllHosts()){
				System.out.println("host :" + host.getAddress());
			}
			
			//输出所有的keyspace
			for ( KeyspaceMetadata keyspace : metadata.getKeyspaces()){
				System.out.println("keyspace :" + keyspace.getName());
			}
			
			cluster.close();
		}
	}




参考：

http://www.ibm.com/developerworks/cn/opensource/os-cn-cassandra/

http://cassandra.apache.org/doc/cql3/CQL.html