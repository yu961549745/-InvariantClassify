$ifndef _CLOSURE
$define _CLOSURE

getClosure:=proc(A::Matrix)
    local _a,_b,n;
    n:=LinearAlgebra[RowDimension](A);
    _a:=Matrix(1,n,[seq(a[i],i=1..n)]);
    _b:=_a.A;
    # 对于每个元素，选择表达式中包含的a[k]
    _b:=map(x->indets(x,specindex(a)),_b);
    print(_b^%T);
    return ;
end proc:

$endif