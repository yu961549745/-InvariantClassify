# 区间操作对象
基于Maple的`RealRange`实现了`Seg`对象，能够进行实数区间的若干操作：
+ 交集：`and` 		或 `intersect`。
+ 并集：`or`  		或 `union`。
+ 补集：`not` 		或 `&C`。
+ 差集：`xor` 		或 `minus`。
+ 子集：`implies` 	或 `subset`。
+ 运算符优先级同maple，`&C > intersect > union = minus > subset > not > and > or > xor > implies`。因此，为了能够保证优先级符合直觉，应当统一使用两套操作符中的一套。才能满足 `补集 > 交集 > 并集 >= 差集 > 子集`
	+ 使用 `and or not xor implies`，并集 > 差集 。
	+ 使用 `intersect union &C minus subset`， 并集 = 差集。
	+ 为了运算顺序更加清晰，推荐添加括号。

相比于`RealRange`具有以下优点：
+ 显示更加直观。`Seg`对象采用习惯上的区间表示方法来显示区间。
+ 计算更加完整。`RealRange`主要基于`AndProp`和`OrProp`进行集合的交并运算，但是有时不能得到理想的结果，尤其不能展开`A⋃(B⋂C)`以及`A⋂(B⋃C)`这种结果。
+ 操作更加方便。采用重载操作符进行计算，可以和集合对象一样使用`intersect`/`and`,`union`/`or`,`not`,`minus`,`subset`等操作，简单直观。
+ 对象形式更加统一。事实上`RealRange`属于Maple的属性类型，还包含常数、集合、`real`,`BottomProp`,`AndProp`,`OrProp`等多种形式，不利于识别和操作。

## 对象初始化
`Seg`对象提供了3种初始化方法：
+ 利用不等式约束集合进行初始化，适合在将单变量约束条件转化为区间表示时使用。
+ 利用`RealRange`初始化，兼容Maple的RealRange表达式。
+ 利用字符串进行初始化，适合手工输入时使用，简单直观。

### 利用不等式约束的集合进行初始化
约束支持等式约束和不等式约束，集合内的约束条件表示且的关系，且所有约束只能使用同一个未赋值的变量。

输入：
```
Seg({x>0,x<=2,x<>1});
```
输出：
```
( 0 , 1 ) ⋃ ( 1 , 2 ]
```

### 利用RealRange进行初始化
更准确的说，是利用Maple的`property`进行初始化，已经考虑到的类型包含：
+ RealRange
+ Non
+ AndProp
+ OrProp
+ real
+ BottomProp
+ set
+ numeric

Maple的`property`类型还包含更多类型，例如`posint`等等，并没有考虑在内。

输入：
```
Seg(RealRange(Open(sqrt(2)),infinity));
```
输出：
```
( 2^(1/2) , +∞ )
```

此外，还提供了两个操作`RealRange`对象的函数：
+ `Seg:-formatRange`，支持将`RealRange`对象表示为区间的形式，但不支持初始化所支持的所有元素，只支持`RealRange AndProp OrProp real BottomProp numeric`这些类型的元素构成的表达式，并且不会对表达式进行求值。事实上，Maple参数传递自带一次求值，所以所谓的不求值只是保留了Maple原生的处理结果，如果要抑制传参的时候进行求值，需使用`''`。
+ `Seg:-evalRange`，支持初始化所支持的所有元素。

### 利用字符串进行初始化
上面两种初始化方法都不够方便，直接使用字符串进行直观的初始化更佳。

输入：
```
# 使用非特殊字符初始化，人工输入推荐使用该方法
Seg("< < ( 0 , 1 ) or ( 1 , 2 ] > and ( 2^(1/2) , +infinity ) > or {3,4}");
# 使用特殊字符初始化，可以将输出结果转化回Seg对象
Seg("( 2^(1/2) , +∞ ) ⋂ < ( 0 , 1 ) ⋃ ( 1 , 2 ] ⋃ [ 3 , 4 ] >");
```
输出：
```
( 1/2*exp(1) , 2 ] ⋃ {3} ⋃ {4}
( 2^(1/2) , 2 ] ⋃ [ 3 , 4 ]
```

需要注意以下几点：
+ 为了便于识别，使用尖括号`<>`来作为区间运算的括号。
+ 如上例所示，输入中可以使用特殊字符`⋂⋃∞`，但是这种用法只推荐在将`Seg`对象的输出结果转化为`Seg`对象时使用。
+ 输入时可以包含计算：`intersect`/`and`,`union`/`or`,`not`,`minus`,`subset`。
+ 用户需要保证表达式的正确性。
+ 初始化时支持使用点集初始化，例如上例中的`{3,4}`，但是输出时会采用单点区间的标准形式`{3} ⋃ {4}`进行输出。该规则同样适用于`RealRange`初始化方法。

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

此外，还解决了这些`RealRange`的不足：
+ `Non`操作的表示，事实`上Non(2)`不会表示为`OrProp(RealRange(-infinity,Open(2)),RealRange(Open(2),infinity))`。
+ 对于`infinity`的相关处理以及对空集的判定。例如`RealRange(Open(infinity),infinity)`应当判定为空集。
+ `AndProp(1,RealRange(1,2))`这种不彻底的计算情况。
+ `OrProp({1,2},{2,3})`这种情况，通过展开集合实现彻底计算。