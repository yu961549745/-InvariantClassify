# 常用代码工具

## 自定义package工具：LibMaker
主要实现了以下功能：
```
MakeLib:=proc(mName,fName:="lib.mla")
```
能够：
+ 能够指定打包到哪个文件。
+ 在库文件不存在的情况下自动创建库文件。

## 基于Maple的代码读取工具：MapleCodeReader
实现了
```
ReadCode:=proc(fname)
```
相比于`read`命令：
+ 解决了只能在同一目录下读取文件的问题。`read`命令在读取其它目录的文件时，如果存在相对路径指定的`$include`，则会读取失败。

具有以下限制：
+ 预处理器必须在行首。
+ include的相对路径必须以 . 或 .. 开头。
+ 文档编码必须是UTF-8。

## 基于Java的代码读取工具：JavaCodeReader
实现了代码读取
```
ReadCode:=proc(fname::string,inEncode:="UTF8",outEncode:="UTF8")
```
以及生成单文件代码
```
ParseCode:=proc(fin::string,fout::string,inEncode:="UTF8",outEncode:="UTF8")
```

相比于基于Maple自身的读取方法，具有以下优点：
+ 可以去除预处理器必须在行首的限制。
+ include默认使用相对路径。
+ 可以指定文件编码。
+ 默认每个文件只会include一遍。

缺点在于需要带着 *CodeParse.jar* 支持。支持jar文件自动寻找，只需保证`libname`指定的目录下存在 *CodeParse.jar* 即可。

基于这个思路，其实以后可以定义一些语法，形成一种Maple的方言，自己实现编译器，来解决一些Maple语言存在的问题。

比如：
+ 变量的声明只能放在`proc`或`module`的头部。这是一种很不好的做法呀，当然变量应该在使用的时候声明才是最好的。
+ 预处理器必须在行首。这个要求也太逗了吧。
+ 面向对象的实现，Maple的面向对象存在一些奇怪的问题：
    + 没有对象的比较方法，无法对其进行唯一化操作。
    + 继承：对象使用`module option object`实现的，但是继承使用`Record`对象实现的，两者是不相关的，你这不是在逗我。
+ 没有`switch`语法。
+ 正则表达式简直智障。好吧这个应该自己实现了，其实委托java实现一个还是挺简单的。
+ 还可以添加一些其它高级语言特性。
