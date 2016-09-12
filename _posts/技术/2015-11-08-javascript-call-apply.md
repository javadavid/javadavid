---
layout: post
title:  "关于js中 apply call 理解"
date:   2015.11.08 15:13:04 
categories:
- 技术
tags:
- Javascript
---
### 关于apply和call的应用；
作用：

> 改变函数作用域

#### 1、语法
	
	fun.apply(obj,[params...])

#### 2、实例
	
	window.firstName = "diz";
	window.lastName = "song";
	var myObject = { firstName: "my", lastName: "Object" };
	function HelloName() {
		console.log("Hello " + this.firstName + " " + this.lastName, " glad to meet you!");
	}
	HelloName.call(window); //who .call(this);
	HelloName.call(myObject); 

#### 3、注意

	fun.call(obj):return boolean

	function(){ fun.call(obj) }:return function 


