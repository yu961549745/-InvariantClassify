(*
    以代表元为核心的对象
    主要以con划分对象，isol和tsol仅做参考作用
*)
RepSol:=module()
    option object;
    export  rep,        # 代表元
            con:=[],    # 成立条件，包括不变量方程和取到isol和tsol所需的条件，是一个代表元所代表的区域所满足的方程
            isol:=[],   # 代表元的通解
            tsol:=[];   # 代表元通解和特解的转化

    # 用于拓展一个代表元对象所能代表的区域
    export  appendSol::static:=proc(r::RepSol,s::InvSol)
        local ieq,isol,icon,tsols,tcons,i,n;
        if not assigned(r:-rep) then
            r:-rep:=s:-rep;
        end if;
        ieq:=s:-ieq;
        isol:=s:-isol;
        icon:=s:-icon;
        tsols:=rmlist(s:-tsol);
        tcons:=rmlist(s:-tcon);
        n:=numelems(tsols);
        for i from 1 to n do
            apList(r:-con,getCon(ieq,icon,tcons[i]));
            apList(r:-isol,isol);
            apList(r:-tsol,tsols[i]);
        end do;
        return;
    end proc:
    # 构造广义的约束
    # 但是没有考虑到约束和epsilon有关该怎么办
    local getCon::static:=proc(ieq,icon,tcon)
        return {ieq[],icon[],tcon[]};
    end proc:
    # 去掉一层嵌套list
    local rmlist::static:=proc(x)
        return map(y->y[],x);
    end proc:
    # 拓展list
    local apList::static:=proc(lst::evaln)
        lst:=[eval(lst)[],_rest];
        return;
    end proc:
    # 输出结果
    # 输出时去除了重复条件，但是实际可能对应不同的isol和tsol
    export printSol::static:=proc(r::RepSol)
        print(r:-rep);
        print~({r:-con[]});
        return ;
    end proc:
    # 输出完整结果
    export fullPrintSol::static:=proc(r::RepSol)
        local i,n;
        print(r:-rep);
        n:=numelems(r:-con);
        for i from 1 to n do
            printf("[%d]------------------------------------------------------\n",i);
            print(r:-con[i]);
            print(r:-isol[i]);
            print(r:-tsol[i]);
        end do;
    end proc:
end module: