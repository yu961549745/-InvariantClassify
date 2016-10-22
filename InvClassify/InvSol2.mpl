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
                            # 4：等待选择最优代表元
                            # 5：求解完成       
            oeq::static,    # 偏微分方程组，
                            # 迭代过程中oeq保持不变
                            # 通过变量代换来获取实际的oeq
            Deltas:=[],     # 不变量
            orders:=[],     # 不变量的阶数
            ieq:=[],        # 不变量方程程组，按不变量排序
            ieqCode:=0,     # 不变量方程的编号
            isols:=[],      # 不变量方程组的解
            icons:=[],      # 不变量方程组对应的条件
            isolInd:=1,     # 通解的下标
            useBranch:=false,# 使用分支求解则假设每个特解都是不等价的
            rsols:=[],      # 不变量方程的特解
            tsols:=[],      # TeqSol对象list
            tsolsList,      # TsolsList 对象
            rep,            # 代表元
            # 最优变换方程的解
            teq,
            tInd,            
            tsol,
            tcon,

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
            getSubs::static,     # 在求解新的不变量时代入的条件
            updateVars::static,  # 更新求解变量 
            getRealOeq::static,  # 获取代换后的oeq
            getZeroCons::static, # 获取为零约束
            addZeroCons::static, # 添加为零约束
            getIsolCons::static, # 返回通解的约束
            displayIeq::static,  # 显示不变量方程
            printSol::static,
            getDisplayIeq::static,
            getDisplayCons::static,
            uniqueKey::static,
            ModulePrint::static; # 显示函数

    getIsolCons:=proc(s::InvSol)
        return s:-addcons union s:-discons union s:-icons[s:-isolInd];
    end proc:

    ModulePrint:=proc(s::InvSol)
        if s:-state<5 then
            return sprintf("unsolved %d",s:-state);
        else
            return s:-rep;
        end if;
    end proc:

    uniqueKey:=proc(s::InvSol)
        return ModulePrint(s);
    end proc:

    printSol:=proc(s::InvSol)
        if s:-state<5 then
            printf("求解失败 %d",s:-state);
        else
            printf("--------------------------------\n");
            print(s:-rep);
            print(getDisplayCons(s));
            if s:-isols<>[] then
                print(s:-isols[s:-isolInd]);
                print(s:-tsol);
                print(s:-tcon);
            end if;
        end if;
    end proc:

    getDisplayIeq:=proc(s::InvSol)
        return [seq(Delta[i]=rhs(s:-ieq[i]),i=1..numelems(s:-ieq))];
    end proc:

    getDisplayCons:=proc(s::InvSol)
        local res:={};
        if s:-isols<>[] then
            res:=res union s:-icons[s:-isolInd];
        end if;
        res:=res union s:-addcons union s:-discons;
        res:=res minus convert(s:-ieq,set);
        return [getDisplayIeq(s)[],res[]];
    end proc:
    
    getSubs:=proc(s::InvSol)
        local r;
        r:=getZeroCons(s);
        r:=[r[]];
        if s:-isols<>[] then
            r:=[r[],s:-isols[s:-isolInd][]];
        end if;
        return remove(x->evalb(lhs(x)=rhs(x)),{r[]});
    end proc:

    updateVars:=proc(s::InvSol)
        s:-vars:=s:-vars minus indets(lhs~(getSubs(s)),name);
    end proc:

    getRealOeq:=proc(s::InvSol)
        local oeq:=s:-oeq;
        updateVars(s);
        oeq:=PDETools:-dsubs(phi(seq(a[i],i=1..s:-nvars))=phi(s:-vars[]),oeq);
        oeq:=eval(subs(getSubs(s)[],oeq)) minus {0};
        return oeq;
    end proc:

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
