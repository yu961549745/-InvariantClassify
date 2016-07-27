(*
    以代表元为核心的对象
    主要以con划分对象，isol和tsol仅做参考作用
*)
RepSol:=module()
    option object;
    local  
            # 局部函数 
            getDisplayDcon::static, # 合并显示成立条件
            apList::static,         # 拓展list
            rmlist::static;         # 去除一层嵌套list
    export  
            # 导出变量
            rep,                    # 代表元
            dcon:=[],               # 不变量方程
            acon:=[],               # 附加约束 
            isol:=[],               # 代表元的通解
            tsol:=[],               # 代表元通解和特解的转化
            osol:=[],               # 对应的InvSol对象
            sid:=1,                 # 选择的最简条件   
            # 导出函数
            ## 设置相关
            appendSol::static,      # 扩充一个RepSol对象成立的条件
            getCon::static,         # 获取一个RepSol对象成立的条件
            sortCon::static,        # 对成立条件进行排序
            selectCon::static,      # 选择最简成立条件
            rmCon::static,          # 删除某个成立条件的一部分
            ## 输出相关
            printRep::static,       # 简要显示代表元和所有可能的成立条件
            fullPrintRep::static,   # 显示代表元和完整的成立条件以及对应的不变量方程和变换方程的解
            ModulePrint::static;    # 简要显示代表元

    # 用于拓展一个代表元对象所能代表的区域
    appendSol:=proc(r::RepSol,s::InvSol)
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

    # 拓展list
    apList:=proc(lst::evaln)
        lst:=[eval(lst)[],_rest];
        return;
    end proc:

    # 获取一个RepSol对象成立的条件
    getCon:=proc(r::RepSol)
        return zip((x,y)->[getDisplayDcon(x)[],y[]],r:-dcon,r:-acon);
    end proc:

    # 不变量方程的简化显示
    getDisplayDcon:=proc(dcon)
        local n;
        n:=numelems(dcon);
        return [seq(Delta[i]=rhs(dcon[i]),i=1..n)];
    end proc:

    # 去掉一层嵌套list
    rmlist:=proc(x)
        return map(y->y[],x);
    end proc:

    # 对成立条件进行排序
    sortCon:=proc(r::RepSol)
        local con,ind;
        con:=getCon(r);
        ind:=sort(con,key=(x->numelems(x)),output=permutation);
        r:-dcon:=r:-dcon[ind];
        r:-acon:=r:-acon[ind];
        r:-isol:=r:-isol[ind];
        r:-tsol:=r:-tsol[ind];
        r:-osol:=r:-osol[ind];
    end proc:

    # 选择最简成立条件
    selectCon:=proc(r::RepSol,sid)
        r:-sid:=sid;
        return;
    end proc:

    # 删除某个成立条件的一部分
    rmCon:=proc(r::RepSol,id::posint,con::set)
        r:-acon[id]:=r:-acon[id] minus con;
    end proc:

    # 简要显示代表元和所有可能的成立条件
    printRep:=proc(r::RepSol)
        print(r:-rep);
        print~(getCon(r));
        return ;
    end proc:

    # 显示代表元和完整的成立条件以及对应的不变量方程和变换方程的解
    fullPrintRep:=proc(r::RepSol)
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

    # 简要显示代表元
    ModulePrint:=proc(r::RepSol)
        return r:-rep;
    end proc:
end module: