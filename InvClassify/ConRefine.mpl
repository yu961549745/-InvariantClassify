# 尽可能的化简解的约束

$ifndef _CON_REFINE_
$define _CON_REFINE_

$include "Condition.mpl"
$include "../seg/Seg.mpl"

# 总的简化函数
conRefine:=proc(r::RepSol)
    signRefine(r);
    epRefine(r);
    uniqueAndSort(r);# 简化之后重新对条件进行排序
    return;
end proc:

# 对于代表元v[k]删去a[k]>0.
# 对于代表元-v[k]删去a[k]<0.
# 这里只删去了acon的条件，对于osol并没有进行修改
signRefine:=proc(r::RepSol)
    local vs,k,rc;
    vs:=indets(r:-rep,name);
    if numelems(vs)<>1 then
        return;
    end if;
    k:=op([1,1],vs);
    rc:=eval({a[k]>0,a[k]<0});
    r:-acon:=map(x->x minus rc,r:-acon);
    return;
end proc:

# 尽可能删去和epsilon有关的约束
epRefine:=proc(r::RepSol)
    r:-acon:=epDeal~(r:-acon);
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