# 求解的成立条件

(*
* 求 解的 定义域
* 返回的条件中求解了单变量约束
* 如果无解则返回 x=undefined 的约束用作标记
* 保留了多变量约束
*)
findSolutionDomain:=proc(s)
    local con;
    con:=`union`(findDomain~(rhs~({s[]}))[]);
    return remove(x->type(x,`=`) and (lhs(x)=rhs(x)),classifySolve(con)) 
        union select(x->type(rhs(x),numeric),{s[]});
end proc:

(*
* 求解表达式的定义域
* 只考虑 + * ^ ln
*)
findDomain:=proc(ee)
    local S,r;
    S:={};
    findDomainCondtions(ee,S);
    return S;
end proc:

(*
* 求解表达式的定义域约束条件
* 只考虑 + * ^ ln
*)
findDomainCondtions:=proc(e,S::evaln(set))
    local _e;
    if type(e,`^`) and (not type(op(1,e),numeric)) then
        if (op(2,e)<0) then
            if type(op(2,e),fraction) and type(denom(op(2,e)),even) then
                S:=eval(S) union {op(1,e)>0};
            else
                S:=eval(S) union {op(1,e)<>0};
            end if;
        else
            if type(op(2,e),fraction) and type(denom(op(2,e)),even) then
                S:=eval(S) union {op(1,e)>=0};
            end if;
        end if;
    elif type(e,`+`) or type(e,`*`) then
        for _e in e do
            findDomainCondtions(_e,S);
        end do;
    elif (op(0,e)='ln') and (not type(op(1,e),numeric)) then
        S:=eval(S) union {op(e)>0};
    end if;
end proc:

# 不等式约束分类求解
# 合并单变量约束
# 保留多变量约束
classifySolve:=proc(con::set)
    local t,sd,ns,c,ind,x,sol;
    t:=table();
    ns,sd:=selectremove(x->(numelems(indets(x,name))=1),con);
    for c in ns do
        tappend(t,indets(c,name)[],c);
    end do;
    ind:=[indices(t,nolist)];
    for x in ind do
        sol:=RealDomain:-solve(t[x],{x});
        if (sol=NULL) then
            t[x]:={x=undefined};
        else
            t[x]:=sol;
        end if;
    end do;
    ns:=`union`(entries(t,nolist));
    return sd union ns;
end proc:
