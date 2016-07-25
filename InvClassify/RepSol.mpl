(*
    以代表元为核心的对象
    主要以con划分对象，isol和tsol仅做参考作用
*)
RepSol:=module()
    option object;
    export  rep,        # 代表元
            dcon:=[],   # 不变量方程
            acon:=[],   # 附加约束 
            isol:=[],   # 代表元的通解
            tsol:=[],   # 代表元通解和特解的转化
            osol:=[],   # 对应的InvSol对象
            sid:=1;     # 选择的最简条件     

    # 用于拓展一个代表元对象所能代表的区域
    export  appendSol::static:=proc(r::RepSol,s::InvSol)
        local ieq,sieq,isol,icon,tsols,tcons,i,n;
        if not assigned(r:-rep) then
            r:-rep:=convert(s:-rep,`global`);
        end if;
        ieq:=s:-ieq;
        sieq:={ieq[]};
        isol:=s:-isol;
        icon:=s:-icon;
        tsols:=rmlist(s:-tsol);
        tcons:=rmlist(s:-tcon);
        n:=numelems(tsols);
        for i from 1 to n do
            apList(r:-dcon,ieq);
            apList(r:-acon,classifySolve({icon[],tcons[i][]}) minus sieq);
            apList(r:-isol,isol);
            apList(r:-tsol,tsols[i]);
            apList(r:-osol,s);
        end do;
        return;
    end proc:
    # 获取组合约束
    export getCon::static:=proc(r::RepSol)
        return zip((x,y)->[getDisplayDcon(x)[],y[]],r:-dcon,r:-acon);
    end proc:
    # 不变量方程的简化显示
    local getDisplayDcon::static:=proc(dcon)
        local n;
        n:=numelems(dcon);
        return [seq(Delta[i]=rhs(dcon[i]),i=1..n)];
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
    export printRep::static:=proc(r::RepSol)
        print(r:-rep);
        print~({getCon(r)[]});
        return ;
    end proc:
    # 输出完整结果
    export fullPrintRep::static:=proc(r::RepSol)
        local i,n,con;
        print(r:-rep);
        con:=getCon(r);
        n:=numelems(con);
        for i from 1 to n do
            printf("[%d]------------------------------------------------------\n",i);
            print(con[i]);
            print(r:-isol[i]);
            print(r:-tsol[i]);
        end do;
    end proc:
    # 简单显示
    export ModulePrint::static:=proc(r::RepSol)
        return r:-rep;
    end proc:
    # 对条件按复杂度进行排序
    export sortCon::static:=proc(r::RepSol)
        local con,ind;
        con:=getCon(r);
        ind:=sort(con,key=(x->numelems(x)),output=permutation);
        r:-dcon:=r:-dcon[ind];
        r:-acon:=r:-acon[ind];
        r:-isol:=r:-isol[ind];
        r:-tsol:=r:-tsol[ind];
        r:-osol:=r:-osol[ind];
    end proc:
    # 选择最简条件
    export selectCon::static:=proc(r::RepSol,sid)
        r:-sid:=sid;
        return;
    end proc:
    # 删除条件
    export rmCon::static:=proc(r::RepSol,id::posint,con::set)
        r:-acon[id]:=r:-acon[id] minus con;
    end proc:
end module: