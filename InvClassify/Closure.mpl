$ifndef _CLOSURE_
$define _CLOSURE_

getClosure:=proc(A::Matrix)
    local _a,_b,n;
    n:=LinearAlgebra[RowDimension](A);
    _a:=Matrix([seq(a[i],i=1..n)]);
    _b:=_a.A;
    _b:=map(x->sym2ind(indets(x,specindex(a))),convert(_b,list));
    return map(findClosure,[seq(1..n)],_b);
end proc:

sym2ind:=proc(s::set)
    return map(x->op(1,x),s);
end proc:

findClosure:=proc(k::integer,A::list)
    local aset,bset;
    aset:={k};
    bset:=A[k];
    while aset<>bset do
        aset:=aset union bset;
        bset:=`union`(A[convert(bset,list)][]);
    end do;
    return aset;
end proc:

$endif