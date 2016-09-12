---
layout: post
title:  "Python 混杂练习（更新） "
date: 2016/5/29 16:33:27 
categories:
- 技术
tags:
- Python
---

	# -*- coding: UTF-8 -*-
	import sys
	import os
	import types
	import math
	import string
	import re
	import operator
	
	# 输出 带回车\n
	print 'hello word'
	
	#判断需要有缩进
	if True:
	    print "true"
	else:
	    print "false"
	
	day = ["one", "two", "three",
	       "four"]
	
	# 接收用户输出
	#print raw_input("user input")
	
	#变量类型
	counter = 1000 #整数类型
	meils = 100.0 #浮点型
	name = "John" #字符串类型
	
	
	#赋值操作
	a = b = c = 1 #变量被附在一个内存空间中
	
	a, b, c = 1, 2, "c"   #按照顺序给abc赋值
	
	
	#删除对象
	del a, b, c
	
	#字符串操作
	s = "ilovepython"
	s[0]  #输出第一个字符串
	s[1:] #范围输出
	s * 2   #输出两次字符串
	s + "test"  #字符串连接操作
	
	
	#List列表
	list1 = [1, "abc", 1.0, 'john', 70.2]
	tinylist = [2, 3, 4, 'math']
	list1[0] #第一个元素
	list1[1:2] #元素范围
	tinylist * 2 #输出两边字符列表
	list1 + tinylist #输出组合列表
	
	
	#tuple元祖列表（只读列表）
	tuple1 = ("abc", 123, '12.3', 70.5)
	tinytuple = ("abc", 123, '12.3', 55.47)
	
	
	#操作输出和上面一样，这里不演示了不一样的是
	
	#tuple1[2] = 1000 # 元组中是非法应用
	#list1[2] = 1000 # 列表中是合法应用
	
	
	#dictionary原字典，相当于一个kv形式
	dict = {}
	dict['one'] = "This is one"
	dict[2] = "this is two"
	tinydict = {'name': 'john', 'code':6734, 'dept': 'sales'}
	
	# for循环 range用于循环下标；len用于计算长度
	list1 = [1, 2, 3, 4, 5, 6]
	for i in range(len(list1)):
	    "list %d = %s" % (i, list1[i])
	
	
	# 下标的另外一种替换方法enumerate
	for i , ch in enumerate(list1):
	    ch , "(%d)" % i
	
	
	# 列表解析
	square = [x ** 2 for x in range(8) if not x % 2]
	
	
	# 异常检查
	try:
	    filename = ""
	    file = open(filename, "r")
	    for eachline in file:
	    print eachline
	    file.close()
	except IOError, e:
	    # print "file is error :" ,e
	    pass
	
	#sys模块
	#不带回车输出
	sys.stdout.write("hello word 2\n")
	# py版本
	sys.version
	# 系统版本
	sys.platform
	
	# 类型
	type(sys).__name__
	
	# 输出对象的属性，若没有指定参数则是 全局的属性
	dir(sys)
	
	num1 = 1
	num2 = 2
	num3 = 3
	
	# \ ：表示不换行
	total = num1 + \
	    num2 + \
	    num3
	
	# '''：表示字符串
	sstr = '''12345
	qwerrt'''
	
	x, y = 1, 2
	# 交换俩元素值
	x, y = y, x
	
	# 换行\r\n \n
	print os.linesep
	
	#切片对象
	foostr = ["1", 3, 4, 5.9, "strss"]
	#反转对象 sequence[start:end:步进值] 数组亦是
	foostr[::-1]
	
	
	# 对象比较
	print "abc" == "xyz" #False
	print 5 + 4j == 3 - 2j #False
	print "abc" >= "xyz" #False
	print ["abc", 123] == ["abc", 123] #True
	print ["abc", 123] == [123, "abc"] #False
	print 3 < 4 < 7 and 3 < 5 < 7 #True
	
	
	a = [1, "a", 1.9]
	b = a
	print a is b #True
	print a is not b #False
	
	#整型对象和 浮点型对象比较  （相同整型不会创建新空间）
	a = 1
	b = 1
	print id(a) == id(b) #True 其中在（-1，100）中间会缓整型存对象
	
	b = 1.0
	print id(a) == id(b) #False
	
	
	class C1(object):pass   # 定义一个继承类
	class C2():pass     # 定义一个普通类
	
	c1 = C1()
	c2 = C2()
	# 返回对象类型
	print type(0xff), type(11L), type(2 - 1j), type(5), type("String"), type(type(1)), type([]), type(()), type({}), type(123 + 1j), type(0L), type(1.0), type(C1), type(c1), type(C2), type(c2)
	
	#types 的 类型判断 
	print type(123) is types.IntType
	
	#关于id list 改变后id地址不变 
	print id(list)
	list1.append("qwe")
	list1[-1] = 7
	print id(list)
	
	#比较对象类型；cmp 返回-1 0 1 
	print cmp(-1, 2), cmp(1, 1), cmp(3, 2), cmp("abc", "xyz"), cmp(0xff, 255), cmp(-6, 2)
	
	print 2 << 32 # 位移操作
	
	#复数  j=根号-1
	aComplex = -8.333 + 1.22j
	print aComplex.real , aComplex.imag , aComplex.conjugate()
	
	
	## / 和  //：地板除 ，  %，**：指数运算
	print 1 / 2.0 , 8 // 3.0 , 1 // 2, 5.0 % 2, 4 ** -1
	
	#运算符  16和10进制、长整型、指数运算、复合型
	print 0x80 + 0777, 55L + 90L, 4.2 ** 3.2, 14 * 0x04, 1 + 1j ** 2, 0 + 1j ** 2, (1 + 1j) ** 2
	
	#str操作
	print str(0XFF), str(55.6e2)
	
	#coerce：可将数组中数据格式统一操作
	print coerce(12, 12.7), coerce(10.0, 10.2e2), coerce(11L, 1.2), coerce(12.3j, 11.2)
	
	#divmod：将出发的商和余数 全部保存在list中
	print divmod(10.0, 3), divmod(2, 10.2)
	
	#pow：指数运算，第三个参数可以是取余运算
	print pow(2, 2), pow(2, 2, 3)
	
	#round():根据精度四舍五入操作   math.floor():返回小于原型的整形浮点数    int():直接截去小数部分
	print round(123.242, 2), math.floor(-1.34), int(12.3)
	
	# 进制数 和 asicc码转换
	print hex(255), oct(222), ord('a'), chr(97), chr(65L), chr(48)
	
	# boolean 和   整型
	print True + 100 , "%d" % True
	
	# boolean 中的方法重载
	class C():
	    def __nonzero__(self): # 重载不为空的返回值
	    return False
	print "%s" % bool(C()), "%s" % bool(C)
	
	#切片操作
	str = '1234567'
	print str[0], str[1:2], str[:2], str[::-1], str[::2]
	
	# 小技巧：使用[None] 添加第一个元素，可以遍历所有元素
	s = 'abcde'
	for i in [None] + range(-1,-len(s),-1):
	    print s[:i]
	
	# string 模块
	print string.lowercase,string.uppercase,string.letters,string.digits
	
	#unicode字符串
	print  u"hello word"
	
	#字符串、数字 格式化（#：表示在进制数前面加上0x操作符号，+：表示数字格式化显示符号操作；0：表示前面补足0；%g：是表示%f和%e的合体）
	print "%x" % 108 
	print "%X" % 108 
	print "%#x" % 108 
	
	print "%.2f" % 108.23450
	print "%.2e" % 108.23450
	print "%g" % 108.23450
	print "%e" % (11111111111L)
	print "%+d" % -2
	print "%+04d" % -2
	
	# 使用元祖类型匹配输出
	print "There is %(howmany)d %(lang)s Quotation Symbols" % {'lang':'python','howmany':3}
	
	# 字符串模版
	s = string.Template("There is ${howmany} ${lang} Quotation Symbols")
	print s.substitute(lang="python",howmany=3),s.safe_substitute(lang="python")
	
	print ur"hello\nword"
	
	# 组合字符串[()]:返回元祖的集合
	print zip('abc','can')
	
	print unichr(12345)
	
	# 字符串内置方法
	quest = " what is your favorite color? "
	print quest.capitalize()
	print quest.center(40)
	print quest.count("or")
	print quest.endswith("color?")
	print quest.find("or",30)
	print quest.count("or",22)
	print quest.index("or",10)
	print ":".join(quest.split())
	print quest.strip() #去掉前后空格
	
	# 序列类型函数 sorted 排序 和 reversed 反转   拥有返回值；
	s = ['they','stamp','them','when',"they're",'small']
	print [temp for temp in reversed(s)],sorted(s)
	
	
	
	# enumerate() 和  zip()
	s1 = ['they','stamp','them','when',"they're",'small']
	for i,album in enumerate(s):
	    print i,album
	for i,j in zip(s,s1):
	    print ('%s %s' % (i,j)).title()
	
	
	# sum()
	num = [3,4,6]
	print reduce(operator.add,num),sum(num,19)
	
	# list() 和tuple()
	aList = ['tao',93,99,'time']
	aTuple = tuple(aList)
	anotherList = list(aTuple)
	print aList,aTuple,aList == anotherList , aList is anotherList, [id(x) for x in aList,anotherList,aTuple]
	
	# 列表类型内建函数
	music_media = [45]
	music_media.insert(2,"compact disc")    
	music_media.append("long play list")# 从尾部插入
	music_media.insert(2, "8 track tape")
	music_media.index(45)
	music_media.sort()  # 给原始值排序  无返回值
	music_media.reverse()  # 给原始值反转  无返回值
	print music_media
	
	
	
	
	
	# ------------------- 高级部分 -------------
	#类的创建
	class Employer:
	    empcount = 0
	    #构造
	    def __init__(self, name, salary):
	    self.name = name 
	    self.salary = salary
	    Employer.empcount += 1
	    def displayCount(self):
	    print "total employer %d" % self.empcount
	    # className
	    print self.__class__.__name__  
	    # 类的属性成员字典
	    print self.__class__.__dict__  
	    # 所处的超类
	    print self.__class__.__bases__
	    # 类定义的模块
	    print self.__class__.__module__
	    def displayEmployer(self):
	    print "Name: ", self.name, "Salary:", self.salary
	    # 对象的销毁
	    def __del__(self):
	    print self.__class__.__name__ , "销毁"
	
	#类的调用
	emp1 = Employer("john1", 100)
	emp2 = Employer("john2", 10)
	
	#方法调用
	emp1.displayCount()
	emp1.displayEmployer()
	print "total count : %d" % Employer.empcount
	
	#属性的增加和删除
	emp1.age = 5
	emp2.age = 8
	
	# 对象属性的的销毁
	del emp1.age
	# 销毁2个对象
	del emp1, emp2 









