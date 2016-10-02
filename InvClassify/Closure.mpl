$ifndef _CLOSURE_
$define _CLOSURE_

# 寻找变换矩阵的闭包
getClosure:=proc(A::Matrix,sol:=[])
    local _a,_b,n;
    n:=LinearAlgebra[RowDimension](A);
    _a:=Matrix([seq(a[i],i=1..n)]);
    _a:=subs(sol[],_a);
    _b:=_a.A;
    _b:=map(x->sym2ind(indets(x,specindex(a))),convert(_b,list));
    return map(findClosure,[seq(1..n)],_b);
end proc:

# 提取a[k]的下标
sym2ind:=proc(s::set)
    return map(x->op(1,x),s);
end proc:

# 寻找某个元素所在的最小闭包
findClosure:=proc(k::integer,A::list)
    local aset,bset;
    aset:={};
    bset:=A[k];
    while aset<>bset do
        aset:=bset;
        bset:=`union`(bset,A[convert(bset,list)][]);
    end do;
    return aset;
end proc:

$endif