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
$include "GenSol.mpl"

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
    flogf[0](convert(procname,string));
    if      (s:-state=0) then
        return solveOeq(s);     # 针对偏微分方程组进行求解
    elif    (s:-state=1) then
        return solveIeq(s);     # 针对不变量方程进行求解
    elif    (s:-state=2) then
        return checkNewInvariants(s); # 检查是否产生了新的不变量
    elif    (s:-state=3) then
        return solveTeq(s);    # 求解变换方程
    else
        error "unkown state";
    end if;
end proc:

# 针对偏微分方程组进行求解
solveOeq:=proc(s::InvSol)
    local deltas;
    flogf[0](convert(procname,string));
    deltas:=getNewInvariants(s);
    if deltas=[] or convert(deltas,set) subset convert(s:-Deltas,set) then
        flogf[1]("没有新的不变量");
        solveByClosure(s);
    else
        flogf[1]("解得新的不变量");
        flog[1]~(deltas);
        genIeq(s,deltas);
    end if;
end proc:

# 求解新的不变量
# 两处判断用的都是这个函数，因此要考虑通用性，代入的条件到底是什么，
# 该如何定义，该如何和别的地方进行协调？
getNewInvariants:=proc(s::InvSol)
    local oeq,deltas;
    flogf[0](convert(procname,string));
    flogf[0]("-------------------------------------------------");
    flogf[0]("求解新的不变量");
    flogf[0]("附加约束");
    flog[0](s:-addcons);

    oeq:=getRealOeq(s);
    flogf[0]("偏微分方程组");
    flog[0](oeq);

    # 求解新不变量（已化简）
    deltas:=getInvariants(oeq);

    # 检查是否有解
    if not type(indets(deltas,name),set(specindex(a))) then
        deltas:=[];
    end if; 

    return deltas;
end proc:

# 按封闭进行求解
solveByClosure:=proc(s::InvSol)
    local c,s1,s2;
    flogf[0](convert(procname,string));
    c:=getMinClosure(getClosure(s:-A,getZeroCons(s)));
    c:={seq(a[x],x in c)};
    # 封闭不全为零
    flogf[1]("封闭不全为零");
    flog[1](c);
    s1:=Object(s);
    # 添加展示性约束
    s1:-discons:=s1:-discons union {add(a[x]^2,x in c)<>0};
    s1:-rep:=v[op([1,1],c)];
    s1:-state:=4;
    addSol(s1);
    # 封闭全为零
    s2:=Object(s);
    # 这里选择了在addcons中加入信息，而不是加入到解中
    solveClosureAllZero(s2,c);
end proc:

# 处理封闭全为零的情况
solveClosureAllZero:=proc(s::InvSol,c::set(specindex(a)))
    local s1;
    flogf[0](convert(procname,string));
    flogf[1]("-------------------------------------------------");
    flogf[1]("封闭全为零");
    flog[1](c);
    addZeroCons(s,{seq(x=0,x in c)});
    updateVars(s);
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
    flogf[0](convert(procname,string));
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
    flogf[0](convert(procname,string));
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
    flogf[0](convert(procname,string));
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
    flogf[0](convert(procname,string));
    if rs=[] then
        return 0;
    else
        return op(1,rs[-1]);
    end if;
end proc:

# 求解不变量方程
solveIeq:=proc(s::InvSol)
    local isols,icons,acons,tc,cc,discons,subcons,ind,i;
    flogf[0](convert(procname,string));
    flogf[1]("-------------------------------------------------");
    flogf[1]("求解不变量方程");
    displayIeq(s);
    
    # 针对全部变量求解
    isols,icons:=ieqsolve(s:-ieq,{seq(a[i],i=1..s:-nvars)});

    flog[1](isols);
    flogf[1]("约束条件");
    flog[1](icons);

    # 进入封闭的求解条件
    # 若只存在单变量大于零或小于零的的约束，则等价成非零约束进行求解。
    # 只存在常数约束和非零约束
    # 只存在一个具有单个单变量非零约束的一般解
    # 若存在多个具有单个单变量非零约束的一般解，
    #     若两个解不能比较，则选择其中一个进行求解。
    #     若两个解等价，则分别进行封闭求解。
    # 若不能进入封闭进行求解，则一个解对应一个特解分别进行求解

    # 首先满足只存在单变量约束
    acons:=`union`(icons[]);
    if not andmap(x->evalb(numelems(indets(x,name))=1),acons) then
        return branchSolve(s,isols,icons);
    end if;

    # 尝试将大于零或小于零的约束等价为非零约束
    # 单变量约束只有3种可能：= <> <
    acons:=select(type,acons,`<`);
    if acons<>{} then
        tc:=table();
        for cc in acons do
            if lhs(cc)=0 or rhs(cc)=0 then
                tappend(tc,indets(cc,name)[],cc);
            else
                # 存在不是大于零或者小于零的约束，则不进入封闭进行计算
                return branchSolve(s,isols,icons);
            end if;
        end do;
        # 对于同一个变量存在大于零和小于零的约束
        # 一般这个约束会体现在值域的约束中，但是现在还没有计算值域
        # 而且从其次性进行考虑，出现这种值域约束的同时，肯定会出现根号约束，
        # 大部分情况下根号约束是不能处理的，不进行封闭计算。
        # 可以给出一个例子，a[1]^2-a[2]^2=0，可以解出 a[1]=±a[2]
        # 反正太复杂了我不走封闭了
        if ormap(x->evalb(numelems(x)>1),[entries(tc,nolist)]) then
            return branchSolve(s,isols,icons);
        end if;
        discons:={entries(tc,nolist)};
        discons:=map(x->x[],discons);
        subcons:=seq((x)=(indets(x)[]<>0),x in discons);
        # 处理掉<约束之后，只剩下单变量等式约束和非零约束，必然能够进行封闭运算
        s:-discons:=s:-discons union discons;
        icons:=subs(subcons,icons);
    end if;

    # 然后至少要有一个非零约束
    if not ormap(isNonZeroCon,`union`(icons[])) then
        return branchSolve(s,isols,icons);
    end if;

    # 尝试进入封闭
    # TODO 还没加入一般解只有一个非零约束的判定
    ind:=findGenSolInd(icons,s:-nvars);
    if type(ind,posint) then
        # 只有一个极大元
        closureRefine(s,isols,icons,ind);
    else
        # 有多个极大元，在不能比较的部分中选择包含元素个数最少的那组
        ind:=MinSelect(ind,numelems)[];
        for i in ind do
            closureRefine(s,isols,icons,i);
        end do;
    end if;
    
end proc:

# 按照分支方法进行求解
branchSolve:=proc(s::InvSol,isols,icons)
    local i,n,_s;
    flogf[0](convert(procname,string));
    n:=numelems(isols);
    for i from 1 to n do
        _s:=Object(s);
        _s:-isols:=[isols[i]];
        _s:-icons:=[icons[i]];
        _s:-state:=2;
        _s:-isolInd:=1;
        resolve(_s);
    end do;
end proc:


# 解的精简，按照封闭求解
# 方程的解至多只含等式约束和非零的约束
closureRefine:=proc(_s::InvSol,isols,icons,ind::posint)
    local CL,zcons,s,s0,s1;
    flogf[0](convert(procname,string));
    flogf[1]("一般解为");
    flog[1](isols[ind]);
    s:=Object(_s);
    # 取封闭
    CL:=getClosure(s:-A,getZeroCons(s));
    zcons:=select(isNonZeroCon,`union`(icons[]));# 提取约束
    zcons:=indets(zcons,name);# 提取变量
    zcons:=map(x->op(1,x),zcons);# 提取下标
    zcons:=[zcons[]];
    CL:=`union`(CL[zcons][]);
    CL:={seq(a[x],x in CL)};# 系数表示
    flogf[1]("封闭为");
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
    if checkIeq(s,CL) then
        flogf[1]("封闭全为零有解");
        s0:=Object(s);
        solveClosureAllZero(s0,CL);
    else
        flogf[1]("封闭全为零无解");
    end if;
end proc:

# 检查封闭全为零是否满足方程
checkIeq:=proc(s::InvSol,c::set(specindex(a)))
    local eq,e;
    try
        eq:=subs(seq(x=0,x in c),s:-ieq);
        eq:=remove(x->lhs(x)=rhs(x),eq);
        for e in eq do
            if not isVar(lhs(e)) then
                if isVar(rhs(e)) then
                    return false;
                else
                    if lhs(x)<>rhs(x) then
                        return false;
                    end if;
                end if;
            end if;
        end do;
        return true;
    catch :
        return false;
    end try;
end proc:

isVar:=proc(x)
    return indets(x,name)<>{};
end proc:

# 取特解
checkNewInvariants:=proc(s::InvSol)
    local deltas;
    flogf[0](convert(procname,string));
    deltas:=getNewInvariants(s);
    if deltas=[] or convert(deltas,set) subset convert(s:-Deltas,set) then
        flogf[1]("没有新的不变量");
        solveRep(s);
    else
        flogf[1]("解得新的不变量");
        flog[1]~(deltas);
        genIeq(s,deltas);
    end if;
end proc:

# 取特解
solveRep:=proc(s::InvSol)
    local rsols;
    flogf[0](convert(procname,string));
    rsols:=fetchSpecSol~(s:-isols,s:-icons,nonzero);# 针对所有解取特解
    flogf[1]("取特解");
    rsols:=`union`(rsols[]);
    rsols:=convert(rsols,list);
    flog[1](rsols);
    s:-rsols:=rsols;
    s:-state:=3;
    resolve(s);
end proc:

# 建立不变量方程并求解
solveTeq:=proc(s::InvSol)
    local ESC;
    ESC:=map[2](specTeqSolve,s,s:-rsols);
    printESC~(ESC);
end proc:

printESC:=proc(ESC)
    flogf[1]("===============================");
    flog[1]~(ESC[1][2..3]);
    flogf[1]("-------------------------------");
    flog[1]~(ESC[2][2..3]);
    flogf[1]("===============================");
    return;
end proc:

specTeqSolve:=proc(sol::InvSol,spec::list)
    local ax,_ax;
    ax:=Matrix([seq(a[i],i=1..sol:-nvars)]);
    _ax:=Matrix(spec);
    return [solveSpecTeq(ax,_ax,sol),
            solveSpecTeq(_ax,ax,sol)];
end proc:

solveSpecTeq:=proc(va,vb,s::InvSol)
    local teq,tsol,tcon,var,n,eqs,eq,_eq,_con,_sol;
    n:=numelems(va);
    teq:=subs(s:-isols[s:-isolInd][],convert(va-vb.s:-A,list));
    var:={seq(epsilon[i],i=1..n)};
    tsol:=teqsolve(teq,var);
    if (tsol=[]) then
        # 求解失败，尝试二次求解法方法
        # 首次求解
        eqs:=teqsolve(teq);
        # 二次求解
        tsol:=[];
        tcon:=[];
        for eq in eqs do
            _eq,_con:=selectremove(has,eq,epsilon);
            _con:=remove(x->type(x,`=`) and (lhs(x)=rhs(x)),_con);
            _con:=convert(_con,set);
            _sol:=teqsolve(_eq,var,_explicit);
            _con:=map(x->getTsolCons(x,s) union _con,_sol);
            tsol:=[tsol[],_sol[]];
            tcon:=[tcon[],_con[]];
        end do;
    else
        # 求解成功，直接计算约束
        tcon:=map(x->getTsolCons(x,s),tsol);
    end if;
    # 清理矛盾解
    tsol:=zip((s,c)->if (undefined in rhs~(c)) then NULL else s end if,
             tsol,tcon);
    tcon:=remove(c->(undefined in rhs~(c)),tcon);
    return [teq,tsol,tcon];
end proc:

# 自定义变换方程求解函数
teqsolve:=proc({_explicit::boolean:=false})
    local res;
    if _explicit then
        res:=[RealDomain:-solve(_rest,explicit)];
    else
        res:=convert~([RealDomain:-solve(_rest)],radical);
    end if;
    return convert~(res,list);
end proc:

# 获取变换方程的解的约束条件
# 删除只含 epsilon 的约束
# 删除 s:-discons 主要是为了删除只能 a[k]>0 的约束，这依赖于 solveIeq 的相关操作。
# 删除通解中存在的约束
getTsolCons:=proc(tsol,s::InvSol)
    return (select(has,findSolutionDomain(tsol),{a,c}) minus getIsolCons(s));
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