---
layout: post
title:  "Linux下的杂七杂八"
date: 2016/4/25 18:08:57 
categories:
- 技术
tags:
- Linux
---

### Linux的MySql安装

使用yum自动安装：相当于一个自动管理安装包程序，可以从指定服务器下载依赖。无需繁琐操作；第一次运行需要安装epel（yum软件源，里面包含了许多基本源里没有的软件。）

	yum install epel-release

1. 首先查看系统有安装mysql没

		yum list installed mysql*
	
	或者使用
		
		rpm -qa | grep mysql*

	另外 查看服务器上的相关匹配的安装包
	
		yum list mysql* 

2. 安装。后面下载依赖完成后直接同意安装
	
		yum install mysql-server

3. 启动服务(最好是restart)
		
		service mysqld start

4. 创建用户

		# 第一次登录无需密码；
		mysql -uroot -p	
 
		# 创建用户，通配符 % 表示连接的host名称；
		CREATE USER 'root'@'%' IDENTIFIED BY 'admin';	
5. 提升权限

		GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'admin' WITH GRANT OPTION;

6. 刷新权限（这样就能够远程访问 mysql数据库了）

		FLUSH PRIVILEGES;

7. 查看用户
		
		# 选择database
		use mysql ;
		
		# 查看user表
		select host,user,password form user ;
		
		# 修改密码，最后刷新权限就好；
		UPDATE user SET password = PASSWORD('newpass') WHERE user = 'root';

8. 设置编码格式 

		vim /etc/my.cnf
		
		[client]
		default-character-set=utf8
		
		[mysqld]
		default-storage-engine=INNODB
		character-set-server=utf8
		collation-server=utf8_general_ci

如果忘记root密码的处理办法：在etc/my.cnf下面加上skip-grant-tables、restart服务；



### Linux的Redis安装；2016/5/13 10:04:54 补充

1. 不想麻烦的就是通过yum安装

	yum install redis

2. 查看安装路径
		
		# 配置文件路径	/etc/redis.conf：定义端口地址绑定信息和配置服务器PID
		whereis redis
	
		# server路径		/usr/sbin/redis-server：路径下面有客户端redis-cli和服务端
		whereis redis-server
	
3. 关于配置服务启动项目（摘自百科）

	- redis-server：Redis服务器的daemon启动程序
	- redis-cli：Redis命令行操作工具。当然，你也可以用telnet根据其纯文本协议来操作
	- redis-benchmark：Redis性能测试工具，测试Redis在你的系统及你的配置下的读写性能
	- redis-stat：Redis状态检测工具，可以检测Redis当前状态参数及延迟状况。

4. 客户端一些相关命令

	<del style='color:ccc'>http://www.yiibai.com/redis/redis_data_types.html</del>
	
		# 配置文件读取
		config get *
	
		# 字符串
		set/get name 'zhangsan'
	
		# hashes set 其中user:1 为键值
		HMSET user:1 username zhangsan password 123 point 200
	
		# hashes get
		HGETALL user:1	

	
### Linux的Zookeeper安装；

1. 先下载文件；使用wget来下载
	
		# 在opt目录下下载zookeeper
		cd opt  | wget http://apache.fayea.com/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.tar.gz

2. 重命名文件夹
		
		mv zookeeper-3.3.6 zookeeper


3. 复制一个conf文件
	
		cp zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg

4. 编辑下conf文件
		
		vim zoo.cfg

		# ZK的一个时间单位；例如session时间是 2*tickTime
		tickTime=2000
		# ZK在启动的时候检测是时间 次数
		initLimit=10
		# 心跳检测：就是Leader机器 向 Flolwer机器的 检测时间（5 * tickTime ）的 次数
		syncLimit=5
		# 快照 和 日志 （若没有相应文件夹，连接zk会报拒绝连接）
		dataDir=/var/data/zookeeper
		dataLogDir=/var/log/zookeeper
		# 连接ZK的服务端口
		clientPort=2181
		# 配置集群的主机中间的通信，第一个端口 Follower和Leader中间的通信；第二个端口是关于 Leader选举过程中投票通信端口
		server.1=192.168.147.131:2888:3888

5. 在dataDir目录下面建立集群的ID标识`myid`添加`1`

		# 创建目录
		mkdir -p /var/data/zookeeper/
			
		# 建立myid文件
		vim /var/data/zookeeper/myid

6. 添加环境变量后启动
		
		zkServer.sh start

7. 连接测试
		
		zkCli.sh -server 127.0.0.1:2181

8. 查询节点的状态信息
	
		stat /LTS/test_cluster/NODES

		# 创建的事物ID和时间
		cZxid = 0x7
		ctime = Fri Apr 29 10:35:20 CST 2016
		# 更新的事物ID和时间		
		mZxid = 0x7
		mtime = Fri Apr 29 10:35:20 CST 2016
		# 子节点列表ID
		pZxid = 0x173
		cversion = 2
		dataVersion = 0
		aclVersion = 0
		# 临时节点的ID
		ephemeralOwner = 0x0
		# 数据长度字节大小
		dataLength = 0
		# 子节点数量
		numChildren = 2

	
9. 查询节点的数据信息

		get /LTS/test_cluster/NODES

10. 创建节点

		# 临时节点
		create -e /node_3/node_3_1 1234

### Linux的一些常用的命令

1. 通过远程 HTTP1.0 下载文件

		curl -O < url_address >

2. 按照标准输出解压到当前文件夹

		gzip -dc < tar.gz file > | tar xf -

3. 软链接文件夹
	
		ln -s < folder1 > < folder2 >

4. 添加环境变量，并且生效
		
		# 编辑
		vim ~/.bash_profile
		
		# 添加
		if [ -d "$HOME/opt" ]; then
			PATH="$PATH:$HOME/opt/cassandra/bin"
		fi
		
		# 生效
		source .bash_profile


	
		# 或者 编辑
		vim /etc/profile

		# 添加
		export PATH="$PATH:$HOME/opt/cassandra/bin"
		
		# 生效
		source /etc/profile

5. 开机服务启动的命令
		
		# 列出启动列表 （启动状态是根据 runlevel 指定；桌面 N = 5）
		chkconfig --list
		
		# 设置开机启动服务
		chkconfig mysqld on


PS:之前由于对linux不熟悉，这几天我装了数十遍的CentOS,关于基本的一些命令和工具包、操作都有大概的了解，不过这些还需要进行系统学习；
