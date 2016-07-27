# -InvariantClassify
采用不变量方法对偏微分方程生成元的李代数空间进行分类。
整个过程分为分支和合并两大步骤。
+   分支过程：即从生成不变量的偏微分方程出发，逐个建立不变量方程进行求解，对于每个不变量方程的解，
    一个不变量方程的解对应一个InvSol对象，取一个形式简单的解作为代表元，并通过求解变换方程来验证是否能够成为代表元。
+   合并过程：对于求解成功的InvSol对象，按照代表元进行分类，生成RepSol对象，一个代表元对应一个RepSol对象。
    每个RepSol对象对应多个成立条件，成立条件由不变量方程以及解的附加条件构成。然后通过人工的验证补充和删除，
    确定最终的代表元。

## 参考文献
+ Hu X, Li Y, Chen Y. A direct algorithm of one-dimensional optimal system for the group invariant solutions[J]. Journal of Mathematical Physics, 2015, 56(5): 053504.

