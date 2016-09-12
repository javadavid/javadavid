---
layout: post
title:  "Linux 常用命令（1）"
date: 2015/12/12 16:09:00 
categories:
- 技术
tags:
- Linux
---

setup：进入设置页面

ifconfig:查看网络设置

df：查看硬盘的信息


### 目录处理

ls：查看文件列表  

- l:long file:长文件列表  和ll命令行的效果一样
	- 其中前面的文件权限 每3个字符为一个权限，分别是 
**当前用户权限、组权限、其他用户权限**  前面显示的数字是**引用计数**
- h:human:显示文件字节变成KB
- i:可以查看文件的ID号（引用的block块）
- a:可以查看目录下面的文件
- d:查看文件夹的目录信息

cd:change directory 改变文件目录

- cd ..：返回上级目录
- cd -：跳到上次目录
- cd ~：跳到root根目录
- cd .： 跳到当前目录

mkdir:make directory：创建文件目录

- p :可以创建文件队列

pwd:print working directory 打印当前目录

rm -rf：强制删除文件；

- r：文件夹
- f：是否强制删除

mv:移动文件夹


ln -s  < 源文件 > < 目标文件 >：创建文件软连接，其中权限是777管理员。

----------

**2016/5/12 19:02:00  更新**

### 文件查找

- locate：数据库查找文件（存放查找文件名称），速度比较快，默认更新的频率是1天。可以使用updatedb或者locate locate强制更新。配置排除文件放在/etc/updatedb.conf下面

- whereis < 系统命令 >：查找系统命令的相应的路径位置；

- which < 系统命令 >：显示系统显示符号的别名参数（完整执行代码）

- whatis < 系统命令 >：文档说明

- echo $PATH：查找环境变量

- find [搜索范围] -name [搜索文件]：相应位置下搜索相应文件；
		
		# 搜索目录下面 无用户权限的文件
		find /root -nouser

		# 搜索文件下面 前面10天的文件日志
		find /var/log/ -mtime +10

		# 搜索目录下面 相应文件I节点的文件
		find /etc -inum 26547

		# 搜索目录下面 大于20M文件
		find /etc -size +20M

		# 搜索目录下面 大于0-20M文件
		find /etc/ -size +0M -a -size 10k			

		# 搜索目录下面 大于0-20M文件 exec给第二个命令处理
		find /etc/ -size +0M -a -size 10k -exec ls -l {} \

	- *：匹配任意
	- []：匹配选择
	- ?：匹配一个字符
	
- grep [选项] [字符串] [命令]：搜索文件内容的字符串



#### 帮助命令

- man < 系统命令 >：查看官方文档手册

		# 查看命令的等级选择项
		man -f null 
		
		# 查看4级别的文档帮助
		man 4 null
		
		# 查看所有 匹配关键字的命令（和apropos）
		man -k passwd


- < 系统命令 > --help：查找当前命令的相关参数

- help < 命令 >：查找非系统安装的命令的参数用法

- info < 系统命令 >：在文档中查找所有的相关命令


#### 压缩命令

.zip格式：

- zip [目标文件] [源文件]：压缩

		zip zookeeper.zip zookeeper.out

- zip [目标文件]：解压缩

.gz格式：

- gzip [目标文件]：压缩文件
		
		# 压缩目录 参数r：配置文件夹
		gzip -r /opt

		# 压缩目录后保存文件 参数d:保存元文件夹
		gzip -rd /opt

- gzip -d [目标文件]：解压缩。或者使用 `gunzip`


.bz2格式：

- bzip [目标文件]：压缩。不支持目录压缩

		# 压缩目录后保存文件 参数k：保存源文件
		gzip -k abc

- bzip -d [目标文件]：解压缩。


.tar.(bz2/gz)格式：


- tar [选项] [目标名称] [源文件]
	- c：打包/x：解压
	- v：显示过程
	- f：指定打包后面的文件名称
	- z：一直打包成gz格式 

			# 直接压缩成.tar.gz
			tar -zcvf a.tar.gz
	
			# 直接解压缩（把c换成x）
			tar -zxvf a.tar.gz


#### 网络命令

- date：查看当前远程机器时间

- shutdown：会正确保存服务
	- c：取消前一个关机命令
	- h：关机
	- r：重启（常用命令）


- init [0 - 6]：调用系统运行级别、取得系统级别用`runlevel`命令
	- 0：关机
	- 1：单用户（相当于安全模式）
	- 2：不完全多用户，没有NFS服务
	- 3：完全多用户
	- 4：未分配
	- 5：图形界面
	- 6：重启

	> 定义系统进入的默认级别：/etc/inittab文件中设置初始化启动级别


- logout：登出用户；
