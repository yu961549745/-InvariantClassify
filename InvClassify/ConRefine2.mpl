$ifndef _CON_REFINE_
$define _CON_REFINE_

$include "Condition.mpl"
$include "../seg/Seg.mpl"

# 简化变换方程的约束条件
tconRefine:=proc(tcon,s::InvSol)
    local res;
    flogf[1]("简化前");
    flog[1](tcon);
    res:=epDeal(tcon);
    flogf[1]("简化后");
    flog[1](res);
    return res;
end proc:

# 处理每个可能情况的约束条件
epDeal:=proc(s::set)
    local ca,ce,r;
    ce,ca:=selectremove(has,s,epsilon);
    ce:=ceDeal~(ce);
    r:=ce union ca;
    r:=classifySolve(r);
    return r;
end proc:

# 单个关于epsilon的条件处理
ceDeal:=proc(e)
    local rs;
    # 有的时候solve会抽，对于这种情况不做处理
    try
        rs:=conSolve(e);
    catch :
        return e;
    end try;
    if numelems(rs)=0 then
        # 无解则原样返回
        return e;
    elif numelems(rs)=1 then
        # 只有一个解，则不论有多少条件都可以
        return rs[][];
    else
       return multiConRefine(rs);
    end if;
end proc:

multiConRefine:=proc(rs)
    local s;
    # 单变量约束的并集，只处理无约束和，x<>c的约束
    if numelems(indets(rs,name))=1 and 
        andmap(x->evalb(numelems(x)=1),rs) then
        s:=`union`(seq(Seg(x),x in rs));
        if s=real then
            return NULL;
        end if;
        s:=&C s;
        if type(s:-bound,numeric) then
            return indets(rs,name)[]<>s:-bound;
        else
            return e;
        end if;
    # 删去一个共同条件之后能够构成单变量约束的并集
    elif numelems(`intersect`(rs[]))=1 then
        s:=`intersect`(rs[]);
        return s[],multiConRefine(map(x->x minus s,rs));
    else
        return e;
    end if;
end proc:

# 求解不等式，
# 在解中删除自由变量
# 删除和epsilon有关的约束
conSolve:=proc(c)
    local r;
    r:=[RealDomain:-solve(c)];
    r:=map(x->remove(t->evalb(lhs(t)=rhs(t)),x),r);
    r:=map(x->remove(has,x,epsilon),r);
    r:=[{r[]}[]];# 去重
    return r;
end proc:

$endif