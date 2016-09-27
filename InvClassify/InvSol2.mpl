$ifndef _INVSOL_
$define _INVSOL_

InvSol:=module()
    option object;
    export 
            # 公用变量
            As::static,     # 每个生成元的伴随矩阵
            A::static,      # 总的伴随矩阵
            # 实例变量
            state,          # 状态代码
            addCons::set,   # 附加条件，用于带入偏微分方程组
            oeq,            # state=0 偏微分方程组
            Deltas::list,   # state=1 不变量
            ieq::list,      # state=2 不变量方程组，按照不变量顺序排序的完整方程格式
            isols::list,    # state=2 不变量方程的解，按照一般性降序排序
            icons::list,    # state=2 不变量方程的解的对应条件
            reps::list,     # state=3 代表元，按照成立条件的多少升序排序
            rsols::list,    # state=3 代表元对应的特解
            teqs::list,     # state=4 变换方程，一个rep对应两个变换方程
            tsols::list,    # state=4 变换方程的解，一个变换方程对应多个解
            tcons::list,    # state=4 变换方程的解的对应条件
            vars::set,      # 求解不变量方程时的变量集，随着系数被其它系数表示，或者被设为0，变量集变小
            # 导出函数
            ModulePrint::static,    # 简要显示
            print::static;          # 完整显示


    # # 简要显示
    # ModulePrint:=proc(s)
    #     if   (s:-state=0) then
    #         return s:-oeq;
    #     elif (s:-state=1) then
    #         return s:-Deltas;
    #     elif (s:-state=2) then
    #         return s:-ieqs;
    #     elif (s:-state=3) then
    #         return s:-isols,s:-icons;
    #     elif (s:-state=4) then
    #         return s:-rsols;
    #     elif (s:-state=5) then
    #         return s:-teqs;
    #     elif (s:-state=6) then
    #         return s:-tsols,s:-tcons;
    #     end if;
    # end proc:

end module:

$endif
