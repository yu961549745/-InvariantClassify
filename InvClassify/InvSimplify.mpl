(*
    不变量化简的算法如下：
    +	对于每个不变量，
        + 尝试使用其它不变量来进行表示，为了防止循环替代，以及出于化简的目的，只允许表示之后项数变少的替换。
        + 先尝试按照乘法规则进行化简，因式分解之后，删去能够成为不变量的因子。
        + 再尝试按照加法规则进行化简，展开之后，删去能够成为不变量的项。
    +	将无法化简的不变量整体替换回其表达式形式。
    +	消除不变量的系数。
    +	调整不变量的阶数为正整数。
    +	对于能够调整次数的不变量，调整其次数，例如把a[1]^3变成a[1]，把a[1]^4变成a[1]^2。

    重复执行上述算法，直到不能再化简为止。
*)

$ifndef _INVSIMPLIFY_
$define _INVSIMPLIFY_

$include "InvOrder.mpl"

# 化简不变量,不改变不变量的顺序。
simplifyInvariants:=proc(iinvs)
    local x,nx;
    x:=iinvs;
    while true do
        nx:=simplifyInvs(x);
        if (x=nx) then
            break;
        end if;
        x:=nx;
    end do;
    return x;
end proc:

# 内部化简函数
simplifyInvs:=proc(iinvs)
    local invs,tmp,ttmp,i,j,n,vars,vset,vv,v1,v2;
    invs:=iinvs;
    n:=numelems(invs);
    vars:=[seq(_Delta[i],i=1..n)];
    vset:={vars[]};
    # 尝试将不变量进行整体代换并进行化简
    for i from 1 to n do
        # 尝试把每个不变量用其它不变量进行表示
        tmp:=invs[i];
        for j from 1 to n do
            if (i<>j) then
                # 替换时用简单替换复杂的，不用复杂的替换简单的。
                try 
                    ttmp:=myAlgsubs(invs[j]=vars[j],tmp);
                    if ( nops(expand(ttmp)) <= nops(expand(tmp)) ) then
                        tmp:=ttmp;
                    end if;
                catch:
                end try;
            end if;
        end do;
        invs[i]:=spAdd(spMul(tmp));
        if type(invs[i],numeric) then
            invs[i]:=0;
        end if:
    end do;
    vv:=[seq(vars[i]=invs[i],i=1..n)];
    # 将不能化简掉的整体代回原表达式
    while true do
        (v1,v2):=selectremove(e->(indets(rhs(e),name) intersect vset <> {}),vv);
        if (v1=[]) then
            break;
        end if;
        v1:=subs(v2[],v1);
        vv:=[v1[],v2[]];
    end do;
    vv:={vv[]};# 为了按照Delta排序
    vv:=rhs~([vv[]]);# 返回list才能保持顺序不变
    vv:=simpleSimplify~(vv);# 消去整体的倍数
    vv:=invOrd~(vv);# 调整阶数为正整数
    vv:=rmOrd~(vv);# 降次
    vv:=simplify(vv);# 默认化简
    return vv;
end proc:

# 自定义algsubs，解决algsubs对于分式替换的不足
myAlgsubs:=proc(_s::seq(equation),v)
    local s;
    s:=dealsubs~(_s);
    return algsubs(s,numer(v))/algsubs(s,denom(v));
end proc:

# 处理替换等式
dealsubs:=proc(e)
    local l,r;
    l:=lhs(e);
    r:=rhs(e);
    if type(numer(l),numeric) then
        return denom(l)=numer(l)/r;
    elif not type(denom(l),numeric) then
        return numer(l)=denom(l)*r;
    else
        return e;
    end if;
end proc:

# 调整不变量的阶数为正整数
invOrd:=proc(v)
    local ord;
    if type(v,numeric) then 
        return v;
    end if;
    ord:=findInvariantsOrder(v);
    if type(ord,fraction) then
        return v^denom(ord);
    elif (ord<0) then
        return v^(-1);
    else
        return v;
    end if;
end proc:

# 不变量降次
rmOrd:=proc(_v)
    local v,ks,k;
    v:=expand(_v);
    if type(v,`*`) then
        v:=remove(type,v,numeric);
        ks:=map(getOrd,[op(v)]);
        k:=myGcd(ks);
        # 保证偶次不能变奇次
        if type(k,even) then
            k:=k/2;
        end if;
        v:=map(setOrd,v,k);
        return v;
    elif type(v,`^`) then
        if type(op(2,v),even) then
            return op(1,v)^2;
        else
            return op(1,v);
        end if;
    else 
        return v;
    end if;
end proc:

# 获取次数
getOrd:=proc(e)
    if type(e,`^`) then
        return op(2,e);
    else
        return 1;
    end if;
end proc:

# 设置次数
setOrd:=proc(e,k)
    if type(e,`^`) then
        return subsop(2=op(2,e)/k,e);
    else
        return e^(1/k);
    end if;
end proc:

(*
    * 若不变量
    *     D[i]=f(D[j1],D[j2],...,D[jn])+g(a[1],...,a[m]), j1,j2,...,jn!=i
    * 则化简为
    *     D[i]=g(a[1],...,a[m])
*)
spAdd:=proc(ee)
    local e,r;
    e:=expand(ee);
    if type(e,`+`) then
        r:=remove(isInv,e);
        if (r=NULL) then
            r:=0;
        end if;
        return r;
    else
        return e;
    end if;
end proc:

(*
    * 若不变量
    *     D[i]=f(D[j1],D[j2],...,D[jn])*g(a[1],...,a[m]), j1,j2,...,jn!=i
    * 则化简为
    *     D[i]=g(a[1],...,a[m])
*)
spMul:=proc(ee)
    local e,r;
    e:=factor(ee);
    if type(e,`*`) then
        r:=remove(isInv,e);
        if (r=NULL) then
            r:=0;
        end if;
        return r;
    elif type(e,`^`) then
        r:=remove(isInv,op(1,e));
        if (r=NULL) then
            r:=0;
        end if;
        return r^op(2,e);
    else
        return e;
    end if;
end proc:

(*
    * 不变量的简单化简
    * 消去分子分母中的倍数
*)
simpleSimplify:=proc(ee)
    local n,d;
    n:=rmK(numer(ee));
    d:=rmK(denom(ee));
    return simplify(expand(n/d));
end proc:

# 删除多项式的倍数
rmK:=proc(_e)
    local e,r;
    if (_e=0) then
        return 0;
    end if:
    e:=expand(_e);
    if type(e,`+`) then
        # 消除多项式中各项系数的倍数
        r:=e/myGcd(map(x->select(type,x,numeric),[op(e)]));
    elif type(e,`*`) then
        # 消除单项多项式的系数
        r:=remove(type,e,numeric);
    else
        # 不处理无系数单项多项式
        r:=e;
    end if;
    if (r=NULL) or type(r,numeric) then
        r:=1;
    end if;    
    return r;
end proc:

# 多个数的gcd
myGcd:=proc(ks)
    local k,i,n;
    if (ks=[]) then
        return 1;
    end if;
    k:=ks[1];
    n:=numelems(ks);
    for i from 2 to n do
        k:=gcd(k,ks[i]);
    end do;
    return k;
end proc:

# 是否是不变量
isInv:=proc(e)
    return andmap(type,indets(e,name),specindex(_Delta));
end proc:

$endif