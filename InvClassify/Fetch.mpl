(*
    变量可以划分为：
    + 自由变量：在满足非零的前提下可以全部取0。
    + 确定性变量：取值已经确定，或者由其它变量确定。
    + 有约束变量：其约束来自于解的定义域，由解的性质可知，其值不由其它变量所确定。

    处理时主要处理约束条件，自由变量可以加单取0，确定性变量的值已知。在完全处理约束的前提下，无需验证是否满足约束。

    至于如何处理约束：
    + 和c有关的约束：为了能够始终满足约束，特解应当和c有关，可以采取变成等式约束进行求解的方式进行处理。(注意对于单独的c的约束，直接删除)
    + 和c无关的约束：可以简单求解不等式，求解后的结果，都是单边的不等式约束，可以看情况取解。

    对于求解后的结果，可以细分为：
    + 单变量约束，可以按照简单的方法取定特解。
    + 多变量约束，可以在取定其它变量的值之后，转化单变量约束进行处理。
*)

$ifndef _FETCH_
$define _FETCH_

$include "Condition.mpl"
$include "Utils.mpl"

# 取特解
fetchSolRep:=proc(_sol::InvSol,{nonzero::boolean:=false,addcon:={}})
    local sol,con;
    sol:=_sol:-isol;
    con:=_sol:-icon union addcon;
    return fetchSpecSol(sol,con,_options['nonzero']);
end proc:

# 根据方程和约束取特解
fetchSpecSol:=proc(sol::list,con::set,{nonzero::boolean:=false})
    local vars,vf,eq,ca,cc,res,ccv,sc;
    vars:=lhs~(sol);
    vf,eq,ca,cc:=filtCon({sol[],classifySolve(con)[]});
    if cc<>{} then
        # 对于和c有关的不等式约束，转化成等式约束后再进行求解
        cc:=transIeq~(cc);
        ccv:=indets(cc,name);
        ccv:=select(type,ccv,specindex(a));
        sc:=RealDomain:-solve(cc,[ccv[]],explicit);
        res:=map(rebuildAndFetch,sc,vars,vf,eq,ca,nonzero);
        res:=sortByComplexity(res);
        return res[1];
    else
        return fetchByCons(vars,vf,eq,ca,nonzero);
    end if;
end proc:

# 转化关于c的不等式约束之后，再对约束进行分类
rebuildAndFetch:=proc(s,vars,_vf,_eq,_ca,nonzero)
    local vf,eq,ca,cc;
    vf,eq,ca,cc:=filtCon({s[]} union findSolutionDomain(s));
    vf:=_vf minus indets(lhs~(eq),name);
    eq:=eq union _eq;
    ca:=ca union _ca;
    return fetchByCons(vars,vf,eq,ca,nonzero);
end proc:

# 求解关于a的约束之后，转化为单边约束，再逐解取特解
fetchByCons:=proc(vars,vf,eq,ca,nonzero)
    local sca,res;
    sca:=[RealDomain:-solve(ca)];
    res:=map[4](fetchBySingleCons,vars,vf,eq,sca,nonzero);
    if nonzero then
        # 在满足非零要求时，目的是给出所有可能的基
        # 而求解a的约束产生的每个解是不相交的
        # 所以需要合并各个解的基
        return `union`(res[]);
    else
        return sortByComplexity(res)[1];
    end if;
end proc:

# 对于和a有关的约束，采用逐步替换的方法取特解
fetchBySingleCons:=proc(vars,_vf,_eq,_ca,nonzero)
    local vf,eq,ca,sca,res,req,tmp,i,n;
    vf:=_vf;
    eq:=_eq;
    ca:=_ca;
    # 对于单变量约束，采用最邻近整数方式取特解
    # 逐步替换多变量约束中的变量，最终都取得特解
    while true do
        sca,ca:=selectremove(isSingleCon,ca);
        if sca={} then
            break;
        end if;
        sca:=fetchIeq~(sca);
        eq:=eq union sca;
        ca:=subs(sca[],ca);
    end do;
    # 由于对不等约束的求解可能存在等式约束，因此最后剩下的是等式约束
    eq:=eq union ca;
    req:=eq union {seq(x=x,x in vf)};
    req:=rhs~(convert(req,list));
    vf:={seq(x=0,x in vf)};
    res:=eval(subs(vf[],eq[],req));
    if nonzero then
        if andmap(type,res,0) then
            n:=numelems(vf);
            res:={};
            for i from 1 to n do
                tmp:=subsop([i,2]=1,vf);
                res:=res union {eval(subs(tmp[],eq[],req))};
            end do;
        else
            res:={res};
        end if;
    end if;
    return res;
end proc:

# 是否是单变量约束
isSingleCon:=proc(x)
    return not type(x,`=`) and numelems(indets(x,name))=1;
end proc:

# 筛选：自由变量，确定性约束，和c无关的不等式约束，和c有关的不等式约束
# 会删除之和c有关的约束
filtCon:=proc(con::set)
    local ef,eq,ca,cc,rst,vf;
    ef,rst:=selectremove(x->lhs(x)=rhs(x),con);
    eq,rst:=selectremove(type,rst,`=`);
    vf:=indets(ef,name) minus lhs~(eq) minus indets(rst,name);
    cc,ca:=selectremove(has,rst,c);
    cc:=select(has,cc,a);
    return vf,eq,ca,cc;
end proc:

# 将不等式约束转化为等式约束
transIeq:=proc(x)
    if op(0,x)=`<>` or op(0,x)=`<` then
        return lhs(x)=rhs(x)-1;
    elif op(0,x)=`>` then
        return lhs(x)=rhs(x)+1;
    else
        return lhs(x)=rhs(x);
    end if;
end proc:

# 对于 <> < <= 的约束条件取特解
# 取满足条件的最邻近整数
fetchIeq:=proc(x)
    local r;
    if type(x,`<>`) then
        r:=lhs(x)=floor(rhs(x))+1;
    elif type(lhs(x),numeric) then
        if type(x,`<`) then
            r:=rhs(x)=floor(lhs(x))+1;
        else
            r:=rhs(x)=ceil(lhs(x));
        end if;
    else
        if type(x,`<`) then
            r:=lhs(x)=ceil(rhs(x))-1;
        else
            r:=lhs(x)=floor(rhs(x));
        end if;
    end if;
end proc:

$endif