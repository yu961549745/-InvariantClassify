(*
 * 保存不变量分类状态的对象
 * 
 * 状态分为：
 *     1 线性偏微分方程组求解失败
 *     2 不变量方程组求解失败
 *     3 取特解失败
 *     4 变换方程求解失败
 *     5 变换方程求解成功，特解可能是代表元，是否是代表元留给人工判断
*)
$ifndef _INVSOL_
$define _INVSOL_

InvSol:=module()
    option object;
    export
        # 导出变量 
        stateCode::{1,2,3,4,5},     # 状态代码
        oieq:={},                   # 导出新偏微分方程的不变量方程（如果存在的话）
        oisol,                      # 导出新偏微分方程的不变量方程的解（如果存在的话）
        oeq::set,                   # 导出不变量的偏微分方程
        Delta:=[],                  # 不变量
        orders::list,               # 不变量对应的阶数
        ieqCode,                    # 不变量方程的代码
        ieq::list,                  # 不变量方程
        isol,                       # 不变量方程的解（一个InvSol对象只含一个解）
        icon::set,                  # 不变量方程解的条件
        teq:=[[],[]],               # 变换方程（有两个）
        tsol:=[[],[]],              # 变换方程的解，每个方程都有可能有多个解
        tcon:=[[],[]],              # 变换方程的解对于的条件
        rep,                        # 代表元的表达式形式
        rvec,                       # 代表元的系数矩阵形式
        vars,                       # 偏微分方程中的剩余自由变量，初始时为a[1]..a[nvars]
        nvars,                      # 生成元的个数
        As::static,                 # 每个生成元的伴随矩阵
        A::static,                  # 总的伴随变换矩阵
        # 导出函数
        ## 输出相关
        getDisplayIeq::static,      # 简化显示的不变量方程，将不变量的实际表达式简写为Delta
        getDisplayDelta::static,    # 输出不变量
        getDesc::static,            # 获取对象的特征描述
        ModulePrint::static,        # 打印和显示对象的值
        printSol::static,           # 详细显示对象信息
        printTeq::static,           # 显示变换方程的结果
        ## 设置相关
        setRep::static,             # 重新取代表元
        setIsol::static,            # 重新对不变量方程取解
        getRep::static;             # 获取代表元，转化为global对象便于比较

    # 重新取代表元
    setRep:=proc(s::InvSol,rvec::list,{nocheck::boolean:=false})
        local v,r;
        if not nocheck then
            # 解的检验
            r:=eval(subs(seq(a[i]=rvec[i],i=1..numelems(rvec)),s:-ieq));
            if not andmap(evalb,r) then
                error "不是不变量方程的解，代入结果为%1",r;
            end if;
        end if;
        s:-stateCode:=4;
        s:-rvec:=Matrix(rvec);
        s:-rep:=add(rvec[i]*v[i],i=1..numelems(rvec));
        return;
    end proc:

    # 重新对不变量方程取解
    setIsol:=proc(s::InvSol,isol,{nocheck::boolean:=false})
        local r;
        if not nocheck then
            # 解的检验
            r:=RealDomain:-simplify(subs(isol[],s:-ieq));
            if not andmap(evalb,r) then
                error "不是不变量方程的解，代入结果为%1",r;
            end if;
        end if;
        s:-stateCode:=3;
        s:-isol:=isol;
        s:-icon:=findSolutionDomain(isol);
        return;
    end proc:

    # 获取代表元，转化为global对象便于比较
    getRep:=proc(s::InvSol)
        return convert(s:-rep,`global`);
    end proc:

    # 简化显示的不变量方程，将不变量的实际表达式简写为Delta
    getDisplayIeq:=proc(self::InvSol)
        local Delta;
        return {seq(Delta[i]=rhs(self:-ieq[i]),i=1..numelems(self:-Delta))};
    end proc:

    # 输出不变量
    getDisplayDelta:=proc(self::InvSol)
        local Delta;
        return [seq(Delta[i]=self:-Delta[i],i=1..numelems(self:-Delta))];
    end proc:

    # 获取对象的特征描述
    getDesc:=proc(s)
        if   (s:-stateCode=1) then
            return s:-oeq;
        elif (s:-stateCode=2) then
            return getDisplayIeq(s);
        elif (s:-stateCode=3) then
            return s:-isol;
        elif (s:-stateCode=4) then
            return s:-rep;
        elif (s:-stateCode=5) then
            return s:-rep;
        end if;
    end proc:

    # 打印和显示对象的值
    ModulePrint:=proc(s)
        return getDesc(s);
    end proc:

    # 输出解
    printSol:=proc(s::InvSol)
        printf("---------------------------------------------------------\n");
        if     (s:-stateCode=1) then
            printf("新的不变量求解失败，状态代码1\n");
            print(s:-oieq);
            printf("取解\n");
            print(s:-oisol);
            printf("求解失败的偏微分方程为\n");
            print(s:-oeq);
        elif    (s:-stateCode=2) then
            printf("不变量方程求解失败，状态代码2\n");
            print(getDisplayIeq(s));
        elif    (s:-stateCode=3) then
            printf("取代表元失败，状态代码3\n");
            print(getDisplayIeq(s));
            printf("取解\n");
            print(s:-isol);
        elif    (s:-stateCode=4) then
            printf("变换方程求解失败，状态代码4\n");
            print(getDisplayIeq(s));
            printf("取解\n");
            print(s:-isol);
            printf("具有约束\n");
            print(s:-icon);
            printf("取代表元\n");
            print(s:-rep);
            printf("求解失败的两个变换方程为\n");
            print~(s:-teq);
        elif    (s:-stateCode=5) then
            printf("变换方程求解成功，状态代码5\n");
            print(getDisplayIeq(s));
            printf("取解\n");
            print(s:-isol);
            printf("具有约束\n");
            print(s:-icon);
            printf("取代表元\n");
            print(s:-rep);
            printf("变换方程有解\n");
            printTeq(s,1);
            printTeq(s,2);
        end if;
        printf("---------------------------------------------------------\n");
        return;
    end proc:

    # 输出变换方程和解
    printTeq:=proc(sol,pos)
        if (sol:-tsol[pos]=[]) then
            printf("变换方程 %d 无解\n",pos);
            printf("方程为\n");
            print(sol:-teq[pos]);
        else
            printf("变换方程 %d 有解\n",pos);
            printf("方程为\n");
            print(sol:-teq[pos]);
            printf("有解\n");
            print(sol:-tsol[pos]);
            printf("具有条件\n");
            print(sol:-tcon[pos]);
        end if;
    end proc:
end module:

$endif