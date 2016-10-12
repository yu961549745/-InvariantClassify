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
$include "Closure.mpl"
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
        return checkNewInvariants(s); # 检查是否产生了新的不变量
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

# 求解新的不变量
# 两处判断用的都是这个函数，因此要考虑通用性，代入的条件到底是什么，
# 该如何定义，该如何和别的地方进行协调？
getNewInvariants:=proc(s::InvSol)
    local oeq,deltas;

    flogf[1]("-------------------------------------------------\n");
    flogf[1]("求解新的不变量\n");
    flogf[1]("附加约束\n");
    flog[1](s:-addcons);

    # 问：求解新的不变量代入的到底是什么？
    oeq:=subsOeq(s);
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

# 获得新的偏微分方程
subsOeq:=proc(s::InvSol)
    # TODO　成败在此一举了，这里该整合所有属性的含义了
    oeq:=s:-oeq;        # 旧的偏微分方程
    vars:=s:-vars;      # 旧的求解变量
    sol:=getSubs(s);    # 需要替换的解

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
    # 这里选择了在addcons中加入信息，而不是加入到解中
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
    if andmap(type,rhs~(s:-ieq),0) then
        spos:=numelems(s:-Deltas)+1;
        s:-Deltas:=[s:-Deltas[],deltas[]];
        s:-orders:=findInvariantsOrder~(s:-Deltas);
        n:=numelems(s:-Deltas);
        for pos from spos to n do
            buildIeq(s,pos);
        end do;
    else
        appendIeq(s,deltas);
    end if;
end proc:

# 按照拓展的方式生成不变量方程
# 对于 Delta[1]=c[1],...,Delta[n]=c[n]的方程，若生成了新的不变量Delta[n+1]
# 新的方程为Delta[1]=c[1],...,Delta[n]=c[n],Delta[n+1]=c[n+1]
appendIeq:=proc(_s::InvSol,deltas)
    local s,cid,getCname;
    cid:=findCid(_s);
    getCname:=proc()
        cid:=cid+1;
        return c[cid];
    end proc:
    s:=Object(_s);
    s:-Deltas:=[s:-Deltas[],deltas[]];
    s:-orders:=findInvariantsOrder~(s:-Deltas);
    s:-ieq:=[s:-ieq[],seq(deltas[i]=getCname(),i=1..numelems(deltas))];
    s:-state:=1;
    resolve(s);
end proc:

# 按位置进行讨论，建立不变量方程
# 讨论 Delta[k] 的取值
# 此时 Delta[1..(k-1)]=0，Delta[(k+1)..n]=c[j]
buildIeq:=proc(_s::InvSol,pos::posint)
    local s,n,xpos,cid,getCname,x,rs;
    n:=numelems(_s:-Deltas);
    if type(_s:-orders[pos],even) then
        xpos:=[1,-1,0];
    else
        xpos:=[1,0];
    end if;
    cid:=0;# 因为前面全是0
    getCname:=proc()
        cid:=cid+1;
        return c[cid];
    end proc:
    rs:=Array(1..n,x->`if`(x>pos,getCname(),0));
    for x in xpos do
        # 只求解全零方程，其它情况将包含在下一个pos的情况中
        if x=0 and pos<> n then
            next;
        end if;
        rs[pos]:=x;
        s:=Object(_s);
        s:-ieqCode:=getIeqCode();
        s:-ieq:=[seq(s:-Deltas[i]=rs[i],i=1..n)];
        s:-state:=1;
        resolve(s);
    end do;
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

# 求解不变量方程
solveIeq:=proc(s::InvSol)
    local isols,icons,i,n,_s,cons; 
    flogf[1]("-------------------------------------------------\n");
    flogf[1]("求解不变量方程\n");
    displayIeq(s);

    # 问：求解的时候到底是针对所有变量求解，还是针对剩余变量求解？
    # + 针对所有变量求解，则方程的解中包含所有变量的取值信息。
    # + 但是不是通过求解不变量方程而得到的对象，将不含解的信息。

    # 解的信息应该添加在addcons中，还是直接取在解中？
    # + 上面的做法是加在addcons中，那么是否能做到加在解中呢？
    # + 毕竟信息集中才比较好管理。

    # 好了，现在我选择加入到解中，那么又该检查和addcons相关的东西了。
    # 主要是getZeroCons，貌似从解中提取也不是不可以

    # 所以！我要统一放在解中！！！！

    # TODO START POINT -------------------------------------------------------------------------------------
    
    isols,icons:=ieqsolve(s:-ieq,s:-vars);

    flog[1](isols);
    flogf[1]("约束条件\n");
    flog[1](icons);

    # 删除等式约束后，所有解的约束的并集只含单变量非零约束，则按封闭进行求解
    # 允许不同的方程包含不同的单变量非零约束
    cons:=remove(type,`union`(icons[]),equation);
    if andmap(isNonZeroCon,cons) then
        # 按照封闭进行求解
        closureRefine(s,isols,icons);
    else
        # 按照分支方法进行求解
        n:=numelems(isols);
        for i from 1 to n do
            _s:=Object(s);
            _s:-isols:=[isols[i]];
            _s:-icons:=[icons[i]];
            _s:-state:=2;
            _s:-isolInd:=1;
            resolve(_s);
        end do;
    end if;
end proc:

# 解的精简，按照封闭求解
# 方程的解至多只含等式约束和非零的约束
closureRefine:=proc(s::InvSol,isols,icons)
    local ind,CL,zcons,s0,s1;
    # 取一般解
    ind:=findGenSolInd(isols,icons);
    flogf[1]("一般解为：\n");
    flog[1](isols[ind]);
    # 取封闭
    CL:=getClosure(s:-A,getZeroCons(s));
    zcons:=select(isNonZeroCon,`union`(icons[]));# 提取约束
    zcons:=indets(zcons,name);# 提取变量
    zcons:=map(x->op(1,x),zcons);# 提取下标
    zcons:=[zcons[]];
    CL:=`union`(CL[zcons][]);
    CL:={seq(a[x],x in CL)};# 系数表示
    flogf[1]("封闭为\n");
    flog[1](CL);
    # 封闭不全为零
    s1:=Object(s);
    s1:-state:=2;
    s1:-isols:=isols;
    s1:-icons:=icons;
    s1:-isolInd:=ind;
    s1:-discons:=s1:-discons union {add(x^2,x in CL)<>0};
    resolve(s1);
    # 封闭全为零
    s0:=Object(s);

end proc:

# 寻找一般解
# 这个操作只在封闭中出现，因此方程的解至多只含等式约束和非零的约束
# 因此选择具有非零约束的解中，约束最少的一个作为一般解
findGenSolInd:=proc(isols,icons)
    local ind,mnc,n,i,nn;
    ind:=0;
    mnc:=infinity;
    n:=numelems(isols);
    for i from 1 to n do
        nn:=numelems(select(isNonZeroCon,icons[i]));
        if nn>0 and nn<mnc then
            ind:=i;
            mnc:=nn;
        end if;
    end do;
    return ind;
end proc:

# 取特解
checkNewInvariants:=proc(s::InvSol)
    local deltas;
    deltas:=getNewInvariants(s);
    if deltas=[] then
        solveRep(s);
    else
        genIeq(s,deltas);
    end if;
end proc:

# 取特解
solveRep:=proc(s::InvSol)
    local rsols;
    rsols:=fetchSpecSol~(s:-isols,s:-icons,nonzero);
    flogf[1]("取特解\n");
    rsols:=`union`(rsols[]);
    print(rsols);
end proc:

# 检查是否是非零约束
# 只考虑单变量非零约束
# 这里只考虑 x<>0 的形式，不考虑 0<>x 的情况
# 因为在求解约束条件时，能够保证把 0<>x 变成 x<>0
isNonZeroCon:=proc(x)
    return op(0,x)=`<>` and rhs(x)=0 and numelems(indets(x,name))=1;
end proc:

# 不变量方程的求解函数
ieqsolve:=proc(eq::list,vars::set)
    local isols,icons,zcons;
    isols:=convert~([RealDomain:-solve(eq,vars,explicit)],list);
    icons:=findSolutionDomain~(isols);
    # 对于单变量约束的情况，尝试进行补全
    zcons:=select(isNonZeroCon,`union`(icons[]));
    if numelems(zcons)=1 then
        isols:={isols[],convert~([RealDomain:-solve([eq[],indets(zcons,name)[]],vars,explicit)],list)[]};
        isols:=[isols[]];
        isols:=SolveTools[SortByComplexity](isols);
        icons:=findSolutionDomain~(isols);
    end if;
    return isols,icons;
end proc:


$endif