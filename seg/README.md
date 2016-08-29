# 区间操作对象
基于Maple的`RealRange`实现了`Seg`对象，能够进行实数区间的若干操作：
+ 交集：`and` 或 `intersect`。
+ 并集：`or`  或 `union`。
+ 补集：`not`
+ 差集：`minus`
+ 子集：`subset`

相比于`RealRange`具有以下优点：
+ 显示更加直观。`Seg`对象采用习惯上的区间表示方法来显示区间。
+ 计算更加完整。`RealRange`主要基于`AndProp`和`OrProp`进行集合的交并运算，但是有时不能得到理想的结果，尤其不能展开`A⋃(B⋂C)`以及`A⋂(B⋃C)`这种结果。
+ 操作更加方便。采用重载操作符进行计算，可以和集合对象一样使用`intersect`/`and`,`union`/`or`,`not`,`minus`,`subset`等操作，简单直观。

## 对象初始化
### 利用不等式约束的集合进行初始化
约束支持等式约束和不等式约束，集合内的约束条件表示且的关系，且所有约束只能使用同一个未赋值的变量。

输入：
```
a:=Seg({x>0,x<=2,x<>1});
```
输出：
```
( 0 , 1 ) ⋃ ( 1 , 2 ]
```

### 利用RealRange进行初始化
`RealRange`包含`RealRange(a,b)`,`real`,`1`,`Non(1)`等多种形式，详情参考Maple帮助文档。

输入：
```
b:=Seg(RealRange(Open(sqrt(2)),infinity));
```
输出：
```
( 2^(1/2) , +∞ )
```

### 利用字符串进行初始化（待实现）
上面两种初始化方法都不够方便，直接使用字符串进行直观的初始化更佳。可以参考四则运算的解析方法，对字符串进行解析，再进行计算。

## 操作示例
```
# 使用条件集合初始化
# 只能使用同一个未赋值的变量
a:=Seg({x>0,x<=2,x<>1});
# 使用 RealRange 初始化
b:=Seg(RealRange(Open(sqrt(2)),infinity));
c:=Seg(RealRange(2,3));
d:=Seg(RealRange(3,4));
# 并集
c or d;
# 交集
a and b;
# 补集
not a;
# 子集
c subset b;
b subset c;
# 复合运算
(a and b) or (c and d);
(a or d) and (b or c);
```

## 和RealRange的对比
在计算结果上，`Seg`相比于`RealRange`，最大的优点在于计算更加彻底。

接上一节的例子，如果采用`RealRange`进行计算，输入：
```
# 事实上，直接基于 RealRange 计算会存在计算不彻底的情况。
# 以同样的例子进行举例，可以发现 AndProp 和 OrProp 展开不完全。
# 而 Seg 对象则根据集合交并的运算规则，完善了该操作。
`&or`:=proc(x,y)
	return OrProp(x,y);
end proc:
`&and`:=proc(x,y)
	return AndProp(x,y);
end proc:
use `and`=`&and`,`or`=`&or`,
a=a:-bound,b=b:-bound,c=c:-bound,d=d:-bound 
in
(a and b) or (c and d);
(a or d) and (b or c);
end use;
```
将会得到
```
OrProp(3, AndProp(OrProp(RealRange(Open(0), Open(1)), RealRange(Open(1), 2)), RealRange(Open(sqrt(2)), infinity)))
AndProp(OrProp(RealRange(3, 4), RealRange(Open(0), Open(1)), RealRange(Open(1), 2)), RealRange(Open(sqrt(2)), infinity))
```
等价于 ( 为了便于识别，区间运算的括号采用尖括号`<>`进行表示 )
```
< < ( 0 , 1 ) ⋃ ( 1 , 2 ] > ⋂ ( 2^(1/2) , +∞ ) > ⋃ {3}
( 2^(1/2) , +∞ ) ⋂ < ( 0 , 1 ) ⋃ ( 1 , 2 ] ⋃ [ 3 , 4 ] >
```
而不是
```
( 2^(1/2) , 2 ] ⋃ {3}
( 2^(1/2) , 2 ] ⋃ [ 3 , 4 ]
```
忽略形式上的差异，最大的区别在于`RealRange`的展开不够彻底。