$ifndef _TCON_REFINE_
$define _TCON_REFINE_

$include "Condition.mpl"
$include "Utils.mpl"

# 简化变换方程的约束条件
tconRefine:=proc(s::TeqSol)
    s:-tcons:=[map[2](singleRefine,s:-rsol,s:-tcons[1]),
               map[2](singleRefine,s:-rsol,s:-tcons[2])];
    # s:-tcons:=map(x->epDeal~(x),s:-tcons);
    return s;
end proc:

# 对于 v[k] 删去 a[k]>0 和 a[k]<0 约束
singleRefine:=proc(rsol,con)
    local ind,n,rep,vs;
    n:=numelems(rsol);
    rep:=add(rsol[i]*v[i],i=1..n);
    vs:=indets(rep,name);
    if numelems(vs)<>1 then
        return con;
    else
        vs:=op([1,1],vs);
        return con minus {a[vs]>0,a[vs]<0};
    end if;
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