$ifndef _CON_REFINE_
$define _CON_REFINE_

# 总的简化函数
conRefine:=proc(r::RepSol)
    signRefine(r);
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
    
end proc:

# 处理每个可能情况的约束条件
epDeal:=proc(s::set)
    local ca,ce;
    ce,ca:=selectremove(has,s,epsilon);
    ce:=ceDeal~(ce);
    return ce union ca;
end proc:

# 单个关于epsilon的条件处理
ceDeal:=proc(e)
    local rs;
    rs:=conSolve(e);
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