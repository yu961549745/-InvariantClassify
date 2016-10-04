$ifndef _CLASSIFYER_
$define _CLASSIFYER_

$include "Basic.mpl"
$include "Condition.mpl"
$include "Fetch.mpl"
$include "InvOrder.mpl"
$include "InvSimplify.mpl"
$include "Logout.mpl"
$include "Utils.mpl"
$include "InvSol2.mpl"

$include "ClassifyHolder.mpl"

# 绑定函数
reset:=ClassifyHolder:-reset;
addSol:=ClassifyHolder:-addSol;
getSols:=ClassifyHolder:-getSols;
getIeqCode:=ClassifyHolder:-getIeqCode;


# 重新求解的入口
classify:=proc(As,A,eqs)
    local sol,n;
    sol:=Object(InvSol);
    sol:-As:=As;
    sol:-A:=A;
    n:=LinearAlgebra:-RowDimension(A);
    sol:-nvars:=n;
    sol:-vars:={seq(a[i],i=1..n)};
    sol:-oeq:=eqs;
    sol:-state:=0;
    reset();
    resolve(sol);
end proc:

# 可重用的求解入口
resolve:=proc(s::InvSol)
    if      (s:-state=0) then
        return solveOeq(s);     # 针对偏微分方程组进行求解
    elif    (s:-state=1) then
        return solveIeq(s);     # 针对不变量方程进行求解
    elif    (s:-state=2) then
        return solveRep(s);     # 取特解
    elif    (s:-state=3) then
        return sovlveTeq(s);    # 求解变换方程
    else
        error "unkown state";
    end if;
end proc:

# 针对偏微分方程组进行求解
solveOeq:=proc(s::InvSol)
    local deltas;
    deltas:=getNewInvariants(s);
    if deltas=[] then
        solveByClosure(s);
    else
        genIeq(s,deltas);
    end if;
end proc:

# 按封闭进行求解
solveByClosure:=proc(s::InvSol)
    local c,s1,s2;
    c:=getMinClosure(getClosure(s:-A,getZeroCons(s)));
    # 封闭不全为零
    s1:=Object(s);
    # 添加展示性约束
    s1:-discons:=s1:-discons union {add(a[x]^2,x in c)<>0};
    s1:-rep:=v[c[1]];
    s1:-state:=4;
    addSol(s1);
    # 封闭全为零
    s2:=Object(s);
    addZeroCons(s2,{seq(a[x]=0,x in c)});
    solveClosureAllZero(s2);
end proc:

# 处理封闭全为零的情况
solveClosureAllZero:=proc(s::InvSol)
    local s1;
    if numelems(s:-vars)>1 then
        solveOeq(s);
    elif numelems(s:-vars)=1 then
        s1:=Object(s);
        s1:-rep:=v[op([1,1],s:-vars)];
        s1:-state:=4;
        addSol(s1);
    else
        return;
    end if;
end proc:

# 生成不变量方程组
genIeq:=proc(s::InvSol,deltas)
    local spos,pos,n;
    pos:=numelems(s:-Deltas)+1;
    s:-Deltas:=[s:-Deltas[],deltas[]];
    s:-orders:=findInvariantsOrder~(s:-Deltas);
    n:=numelems(s:-Deltas);
    # TODO　建立方程有待考虑
    # 比如重新设计ieqCode为list，使其具有分支标记的功能
    # 应该按照老方法，带着新不变量递归，这样才能正确的分支
    for pos from spos to n do
        buildIeq(s,pos);
    end do;
end proc:

buildIeq:=proc(_s::InvSol,pos::posint)
    local s,n,xpos,cid,getCname;
    s:=Object(_s);
    n:=numelems(s:-Deltas);
    if type(s:-orders[pos],even) then
        xpos:=[1,-1,0];
    else
        xpos:=[1,0];
    end if;
    cid:=findCid(s);
    getCname:=proc()
        cid:=cid+1;
        return c[cid];
    end proc:
    rs:=Array(1..n,x->`if`(x>pos,getCname(),0));

end proc:

# 获取当前c的最后一个下标
# 本做法保证一个不变量方程中的任意常数c，从c[1]开始依次编号
# 而不与其它不变量方程中的任意常数c进行比较
findCid:=proc(s::InvSol)
    local rs:=select(type,rhs~(s:-ieq),specindex(c));
    if rs=[] then
        return 0;
    else
        return op(1,rs[-1]);
    end if;
end proc:



# 求解新的不变量
getNewInvariants:=proc(s::InvSol)
    local oeq,deltas;

    flogf[1]("-------------------------------------------------\n");
    flogf[1]("求解新的不变量\n");
    flogf[1]("附加约束\n");
    flog[1](s:-addCons);

    oeq:=remove(type,subs(s:-addCons[],s:-oeq),0);
    flogf[1]("偏微分方程组\n");
    flog[1](oeq);

    # 求解新不变量（已化简）
    deltas:=getInvariants(oeq);

    # 检查是否有解
    if not type(indets(deltas,name),set(specindex(a))) then
        deltas:=[];
    end if; 

    return deltas;
end proc:

$endif