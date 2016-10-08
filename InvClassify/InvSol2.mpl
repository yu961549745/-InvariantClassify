$ifndef _INVSOL_
$define _INVSOL_

InvSol:=module()
    option object;
    export 
            # 公用变量
            As::static,     # 每个生成元的伴随矩阵
            A::static,      # 总的伴随矩阵
            nvars::static,  # 总的变量个数
            # 实例变量
            state,          # 状态代码，主要为人工干预提供入口
                            # 0：还未生成不变量方程
                            # 1：不变量方程求解失败
                            # 2：取特解失败            
                            # 3：变换方程求解失败
                            # 4：求解完成       
            oeq,            # 偏微分方程组
            Deltas:=[],     # 不变量
            ieq:=[],        # 不变量方程程组，按不变量排序
            ieqCode,        # 不变量方程的编号
            isols:=[],      # 不变量方程组的解
            orders:=[],     # 不变量的阶数
            icons:=[],      # 不变量方程组对应的条件
            rsols:=[],      # 不变量方程的特解
            teq,            # 变换方程
            tsols,          # 变换方程的解
            tcons,          # 变换方程的解对应的条件
            rep,            # 代表元
            vars,           # 需要求解的系数
            # 条件相关
            # 不变量方程+附加约束+展示约束，描述了代表元所代表的元素的范围
            # 后期只维护以下变量，而不修改icons,tcons等原始信息
            addcons:={},    # 附加约束，能够参与计算，其中，
                            # + 等式是对不变量方程的扩充，例如a[1]=0
                            # + 不等式式对取值范围的描述，并能够进行处理，例如a[1]>0
            discons:={},    # 展示约束，仅用于展示信息，不能参与计算，包括
                            # + a[1]*a[3]>0 这种不能处理的多变量约束
            # 导出函数
            getZeroCons::static, # 获取为零约束
            addZeroCons::static, # 添加为零约束
            displayIeq::static,  # 显示不变量方程
            ModulePrint::static; # 显示函数

    getZeroCons:=proc(s::InvSol)
        return select(type,s:-addcons,equation);
    end proc:

    addZeroCons:=proc(s::InvSol,c::set)
        s:-addcons:=s:-addcons union c;
        s:-vars:=s:-vars minus indets(c,name);
    end proc:

    displayIeq:=proc(s::InvSol)
        local n;
        n:=numelems(s:-ieq);
        flog[1]([seq(Delta[i]=rhs(s:-ieq[i]),i=1..n)]);
        flog[1]([seq(Delta[i]=s:-Deltas[i],i=1..n)]);
    end proc:
                            
end module:

$endif
