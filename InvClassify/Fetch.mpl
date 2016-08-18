# 取特解

(*
* 取特解
* 自由变量取0
* 根据单变量约束取最邻近整数
* 验证是否满足多变量约束
* 满足返回特解，否则返回NULL
*)
fetchSolRep:=proc(_sol::InvSol,{nonzero::boolean:=false,addcon:={}})
    local sol,con;
    sol:=_sol:-isol;
    con:=_sol:-icon union addcon;
    return fetchForSolCon(sol,con,_options['nonzero']);
end proc:

# 根据方程的解和条件取特解
fetchForSolCon:=proc(sol::list,con::set,{nonzero::boolean:=false})
    local f,C,sc,vc,t,r,rf,_rf,i,n,sols,res;
    f:=select(x->(lhs(x)=rhs(x)),sol);# 解中的自由变量
    C,t:=selectremove(x->type(x,`=`) and type(rhs(x),numeric),con);# C是等式约束
    sc,vc:=selectremove(x->(numelems(indets(x,name))=1),t);# sc，vc分别为单变量约束和多变量约束
    f:=indets(f,name) minus indets(sc,name);# 删去具有单变量约束的自由变量

    r:=fetchIeq~(sc) union C;
    rf:={seq(x=0,x in f)};
    if andmap(checkIeq,subs(r[],rf[],vc)) then
        res:=eval(subs(r[],rf[],rhs~(sol)));
    else
        res:=NULL;
    end if;
    if nonzero then
        if andmap(type,res,0) then
            sols:={};
            n:=numelems(rf);
            for i from 1 to n do
                _rf:=subsop([i,2]=1,rf);
                if andmap(checkIeq,subs(r[],_rf[],vc)) then
                    sols:=sols union {eval(subs(r[],_rf[],rhs~(sol)))};
                end if;
            end do:
            res:=sols;
        else
            res:={res};
        end if;
    end if;
    return res;
end proc:

# 验证是否满足约束
checkIeq:=proc(ieq)
    local res;
    res:=evalb(ieq);
    # 对于无法判断的不等式，则认为成立
    if not type(res,truefalse) then
        res:=true;
    end if;
    return res;
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

