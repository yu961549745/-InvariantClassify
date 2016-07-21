# -InvariantClassify
采用不变量方法对偏微分方程生成元的李代数空间进行分类。
整个过程分为分支和合并两大步骤。
+ 分支过程：即从生成不变量的偏微分方程出发，逐个建立不变量方程进行求解，对于每个不变量方程的解，取一个形式简单的解作为代表元，并通过求解变换方程来验证是否能够成为代表元。
+ 合并过程：分支过程中对于每个解都会进入下一个步骤进行求解，并保留所有成功和失败的结果，在合并过程中，将会对不变量进行补全和合并。
本程序的基本原理来自于参考文献，但是实际实现以及算法思想是重新设计的。

## 参考文献
+ Hu X, Li Y, Chen Y. A direct algorithm of one-dimensional optimal system for the group invariant solutions[J]. Journal of Mathematical Physics, 2015, 56(5): 053504.

