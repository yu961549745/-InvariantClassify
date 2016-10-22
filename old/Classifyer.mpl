$ifndef _CLASSIFYER_
$define _CLASSIFYER_

$include "Basic.mpl"
$include "Condition.mpl"
$include "Fetch.mpl"
$include "InvOrder.mpl"
$include "InvSimplify.mpl"
$include "InvSol.mpl"
$include "Logout.mpl"
$include "Utils.mpl"

ClassifyHolder:=module()
    option object;
    export 
        cid,        # 当前不变量方程中的常数项下标
        ieqCode,    # 不变量方程编号
        sols,       # 当前所有解
        usols,      # 上一个全零不变量方程的解
        oldSols;    # 上一次getSols的解
end module:

# 状态重置
reset:=proc()
    ClassifyHolder:-cid:=0;
    ClassifyHolder:-ieqCode:=0;
    ClassifyHolder:-sols:={};
    ClassifyHolder:-usols:=table();
    ClassifyHolder:-oldSols:={};
end proc:

# 新增解
addSol:=proc(sol)
    ClassifyHolder:-sols:=ClassifyHolder:-sols union {sol};
    return;
end proc:

# 获取新增的代表元
# 新的代表元只能获取一次
getNewSols:=proc()
    local res;
    res:=sort([ (ClassifyHolder:-sols minus ClassifyHolder:-oldSols)[] ],'key'=(x->x:-ieqCode));
    ClassifyHolder:-oldSols:=ClassifyHolder:-sols;
    return res;
end proc:

getCname:=proc()
    ClassifyHolder:-cid:=ClassifyHolder:-cid+1;
    return c[ClassifyHolder:-cid];
end proc:

getIeqCode:=proc()
    ClassifyHolder:-ieqCode:=ClassifyHolder:-ieqCode+1;
    return ClassifyHolder:-ieqCode;
end proc:

classify:=proc(A,As,eqs)
    local sol;
    reset();
    sol:=Object(InvSol):
    sol:-stateCode:=1:
    sol:-oeq:=eqs:
    sol:-As:=As:
    sol:-A:=A:
    sol:-nvars:=LinearAlgebra[RowDimension](A):
    sol:-vars:=[seq(a[i],i=1..sol:-nvars)]:
    resolve(sol);
    return;
end proc:

# 暂时没做重复代表元的处理
getSols:=proc()
    ClassifyHolder:-oldSols:=ClassifyHolder:-sols;
    return sort([ClassifyHolder:-sols[]],'key'=(x->[x:-ieqCode,convert(getDesc(x),`global`)]));
end proc:

resolve:=proc(sol::InvSol)
    local spos,pos,nDelta,_usols,_usol,oldDeltas,oldSol;
    
    if (sol:-stateCode=1) then
        # 尝试求解偏微分方程组
        # 如果所有方程组为空，则停止求解
        if (sol:-oeq={}) then
            return;
        end if;
        nDelta:=getInvariants(sol:-oeq);
        # 求解失败
        if (indets(nDelta,name) intersect {seq(a[i],i=1..sol:-nvars)} = {}) then
            # 求解失败不添加解
            # 不考虑不能求解不变量的情况
            return "新不变量求解失败";
        end if;
        # 设置新的不变量
        spos:=numelems(sol:-Delta)+1;
        oldDeltas:={sol:-Delta[]};
        oldSol:=Object(sol);
        if (sol:-Delta<>[]) then
            sol:-Delta:=[sol:-Delta[],nDelta[]]:
            # 整体化简不变量
            if (1>=LogLevelHolder:-logLevel) then
                flogf[1]("-----------------------------------------------");
                flogf[1]("对新增不变量按照原不变量进行化简");
                flogf[1]("化简前");
                printDeltas(sol:-Delta);
                sol:-Delta:=simplifyInvariants(sol:-Delta);
                flogf[1]("化简后");
                printDeltas(sol:-Delta);
            end if;
        else
            sol:-Delta:=[sol:-Delta[],nDelta[]]:
        end if;
        sol:-orders:=findInvariantsOrder~(sol:-Delta):# 计算不变量阶数
        # 根据新的不变量是否有约束来决定是否求解上一个全零方程
        nDelta:=remove(x->(x in oldDeltas),sol:-Delta);
        if ( `union`(findDomain~(nDelta)[]) <> {} ) and (sol:-Delta<>[]) then
            solveRestAllZeroIeqs(oldSol);
        end if;
        # 建立和求解不变量方程组
        for pos from spos to numelems(sol:-Delta) do
            buildInvEqs(sol,pos);
        end do;
        # 生成新的不变量
        genInvariants(sol);
    elif (sol:-stateCode=2) then
        # 求解不变量方程组
        solveInvEqs(sol);
    elif (sol:-stateCode=3) then
        # 取代表元
        fetchRep(sol);
    elif (sol:-stateCode=4) then
        # 求解变换方程
        solveTransEq(sol);
    end if;
    return;
end proc:

# 建立不变量的方程组
buildInvEqs:=proc(_sol::InvSol,pos::posint)
    global sols,cid;
    local sol,rs,i,n,x,xpos,eqs;
    n:=numelems(_sol:-Delta);
    # 分奇偶讨论
    if type((_sol:-orders[pos]),even) then
        xpos:=[1,-1,0];
    else
        xpos:=[1,0];
    end if;
    # 生成方程右端
    cid:=0;
    rs:=Array(1..n,x->
    if (x>pos) then
        getCname()
    else
        0
    end if);
    # 逐个方程求解
    for x in xpos do
        # 对于Delta[pos]=0，构建下一个方程进行求解
        # 不求解全零方程
        if (x=0) then
            # 这里是每个全零方程都进行求解的意思
            # 否则直接next就好了
            if (pos<>n) then
                next;
            else
                # 这里是直接求解
                # solveAllZero(_sol);
                
                # 这里是延后求解
                ClassifyHolder:-usols[getUsolsKey(_sol)]:=_sol;
                return;
            end if;

            # next;
        end if;
        rs[pos]:=x;
        eqs:=[seq(_sol:-Delta[i]=rs[i],i=1..n)];
        sol:=Object(_sol);
        sol:-ieqCode:=getIeqCode();
        sol:-ieq:=eqs;
        sol:-stateCode:=2;
        resolve(sol);
    end do;
    return;
end proc:

# 生成新的代表元
genInvariants:=proc(_sol::InvSol)
    local isols,isol,sol;
    sol:=Object(_sol);
    isols:=ieqsolve(sol:-Delta,[seq(a[i],i=1..sol:-nvars)]);
    # 全部求解失败，则求解上一个全零方程
    if andmap(isol->(subsOeq(sol,isol)="新不变量求解失败"),isols) then
        solveRestAllZeroIeqs(sol);
    end if;
end proc:

# 生成新的不变量方程
# 这么写会导致和非自由变量有关的偏导都变成0
subsOeq:=proc(_sol::InvSol,isol)
    local oeq,sol,v,vv,vars,Delta;
    flogf[1]("--------------------------------------------------------------");
    flogf[1]("求解新的不变量");
    flog[1]({seq(Delta[i]=0,i=1..numelems(_sol:-Delta))});
    flog[2](getDisplayDelta(_sol));
    flogf[1]("取解");
    flog[1](isol);
    oeq:=_sol:-oeq;
    vars:=_sol:-vars;
    v,vv:=selectremove(x->(lhs(x)<>rhs(x)),isol);
    vv:=lhs~(vv);# 方程中的剩余自由变量
    oeq:=PDETools:-dsubs(phi(vars[])=phi(vv[]),oeq);
    oeq:=eval(subs(v[],oeq)) minus {0};
    sol:=Object(_sol);
    sol:-oisol:=isol;
    sol:-stateCode:=1;
    sol:-oeq:=oeq;
    sol:-vars:=vv;
    return resolve(sol);
end proc:

# 求解不变量方程组
solveInvEqs:=proc(_sol::InvSol)
    local isols,icons,n,vars,sol,i;
    n:=_sol:-nvars;
    vars:=[seq(a[i],i=1..n)];
    isols:=ieqsolve(_sol:-ieq,vars);
    icons:=findSolutionDomain~(isols);
    n:=numelems(isols);
    for i from 1 to n do
        sol:=Object(_sol);
        sol:-stateCode:=3;
        sol:-isol:=isols[i];
        sol:-icon:=icons[i];
        resolve(sol);
    end do;
    return;
end proc:

# 对不变量全为0的方程进行求解
solveAllZero:=proc(_sol)
    local sol,var,isols,icons,i,n,reps,rep,nsol,nnsol;
    sol:=Object(_sol);
    sol:-ieq:=[seq(x=0,x in sol:-Delta)];
    sol:-ieqCode:=getIeqCode();
    var:=[seq(a[i],i=1..sol:-nvars)];
    isols:=ieqsolve(sol:-Delta,var);
    icons:=findSolutionDomain~(isols);
    n:=numelems(isols);
    for i from 1 to n do
        nsol:=Object(sol);
        nsol:-isol:=isols[i];
        nsol:-icon:=icons[i];
        reps:=fetchSolRep(nsol,nonzero);
        for rep in reps do
            nnsol:=Object(nsol);
            nnsol:-stateCode:=4;
            setRep(nnsol,rep);
            flogf[1]("--------------------------------------------------------------");
            flogf[1]("求解全零方程");
            flog[1](getDisplayIeq(nnsol));
            flog[1](getDisplayDelta(nnsol));
            flogf[1]("取解");
            flog[1](nnsol:-isol);
            flogf[1]("具有约束条件");
            flog[1](nnsol:-icon);
            flogf[1]("取特解");
            flog[1](nnsol:-rvec);
            flogf[1]("取代表元");
            flog[1](nnsol:-rep);
            resolve(nnsol);
        end do;
    end do;
end proc:

# 取代表元
fetchRep:=proc(_sol::InvSol)
    local n,_ax;
    flogf[1]("--------------------------------------------------------------");
    flogf[1]("对于不变量方程");
    flog[1](getDisplayIeq(_sol));
    flog[1](getDisplayDelta(_sol));
    flogf[1]("取解");
    flog[1](_sol:-isol);
    flogf[1]("具有约束条件");
    flog[1](_sol:-icon);
    n:=_sol:-nvars;
    _ax:=fetchSolRep(_sol);
    if (_ax=NULL) then# 取特解失败
        addSol(_sol);
        flogf[1]("取特解失败");
        return;
    end if;
    setRep(_sol,_ax);
    if (_sol:-rep=0) then
        flogf[1]("代表元取0");
        return;
    end if;
    _ax:=Matrix(_ax);
    _sol:-stateCode:=4;
    flogf[1]("取特解");
    flog[1](convert(_ax,list));
    flogf[1]("取代表元");
    flog[1](_sol:-rep);
    resolve(_sol);
end proc:

solveTransEq:=proc(_sol::InvSol)
    local ax,_ax,n,eq,sol,con;
    n:=_sol:-nvars;
    ax:=Matrix([seq(a[i],i=1..n)]);
    _ax:=_sol:-rvec;
    # a_=a.A
    _sol:-teq[1],_sol:-tsol[1],_sol:-tcon[1]:=solveTeq(_ax,ax,_sol);
    # a=a_.A
    _sol:-teq[2],_sol:-tsol[2],_sol:-tcon[2]:=solveTeq(ax,_ax,_sol);
    if andmap(x->(x=[]),_sol:-tsol) then
        # 无解
        flogf[1]("变换方程求解失败");
        addSol(_sol);
    else
        # 有解
        flogf[1]("变换方程有解");
        _sol:-stateCode:=5;
        addSol(_sol);
        # 在logLevel为1时输出
        if (1>=LogLevelHolder:-logLevel) then
            printTeq(_sol,1);
            printTeq(_sol,2);
        end if;
    end if;
    return;
end proc:

(*
    求解变换方程

    ？ 因为变换方程只关心其存在性，而不在乎其完整性，因此不用explicit选项，而采用convert/radical

    是否选择explicit选项也是有待衡量的，example3出现了不用explicit选项则有复杂约束不能简单消去的情况。
    但是选择explicit选项之后，会面临解过多的问题
    两害取其轻，还是取吧

    该二次求解算法的求解能力值得肯定，测试是否可以转化也依赖于该算法，最好不要修改。
    当然也出现过解的的解不满足方程的情况，至于是否要加以验证，还有待考虑。
*)
solveTeq:=proc(a,b,sol)
    local var,teq,tsol,tcon,scon,eqs,eq,_eq,_con,_sol;
    teq:=convert((a-b.sol:-A),list);
    teq:=subs(sol:-isol[],teq);
    var:=[seq(epsilon[i],i=1..sol:-nvars)];
    tsol:=teqsolve(teq,var);
    if (tsol=[]) then
        # 求解失败，尝试二次求解法方法
        # 首次求解
        eqs:=teqsolve(teq);
        # 二次求解
        tsol:=[];
        tcon:=[];
        for eq in eqs do
            _eq:=select(eqOfEpsilon,eq);
            _con:=remove(eqOfEpsilon,eq);
            _con:=remove(x->type(x,`=`) and (lhs(x)=rhs(x)),_con);
            _sol:=teqsolve(_eq,var,_explicit);
            _con:=map(x->clearConditions(findSolutionDomain(x)) union _con,_sol);
            tsol:=[tsol[],_sol[]];
            tcon:=[tcon[],_con[]];
        end do;
    else
        # 求解成功，直接计算约束
        tcon:=map(x->clearConditions(findSolutionDomain(x)),tsol);
    end if;
    # 清理矛盾解
    tsol:=zip((s,c)->if (undefined in rhs~(c)) then NULL else s end if,tsol,tcon);
    tcon:=remove(c->(undefined in rhs~(c)),tcon);
    return teq,tsol,tcon;
end proc:

eqOfEpsilon:=proc(eq)
    return ormap(x->type(x,specindex(epsilon)),indets(eq,name));
end proc:

# 保留和a,c有关的约束
clearConditions:=proc(con)
    return select(has,con,{a,c});
end proc:

# 求解剩余全零不变量方程
solveRestAllZeroIeqs:=proc(sol::InvSol)
    solveAllZero( ClassifyHolder:-usols[getUsolsKey(sol)] );
end proc:

# 获取全零不变量方程在usols中的key
getUsolsKey:=proc(sol)
    return convert([seq(Delta[i],i=1..numelems(sol:-Delta))],`global`);
end proc:

# 自定义不变量方程求解函数
# 
# 采用set的方式指定变量相比于list方式指定变量，解可能更简洁。
# 以为list方式指定变量会优先用后面的变量表示前面的变量，有时这是不好的。
#
# 采用set求解时，example3出现了没有导出a[4]=0的解的情况，例子并不完整。
# 采用list求解时，example包含了a[3]a[4]的约束，也没求解完整。
#
# 可能可以通过自定义补全解的算法来解决这个问题。
# 不过目前只能想到处理不等于0的约束，至于大于0小于0的约束则还没想法。
# 不等于0的约束，可以直接取为0之后再进行求解
ieqsolve:=proc(eq,vars)
    # return convert~([RealDomain:-solve(eq,convert(vars,set),explicit)],list);
    return RealDomain:-solve(eq,vars,explicit);
end proc:

# 自定义变换方程求解函数
teqsolve:=proc({_explicit::boolean:=false})
    if _explicit then
        if _nrest=1 then
            return [RealDomain:-solve(_rest,explicit)];
        elif _nrest=2 then
            return RealDomain:-solve(_rest,explicit);
        else
            error "未知调用方式";
        end if;
    else
        if _nrest=1 then
            return convert~([RealDomain:-solve(_rest)],radical);
        elif _nrest=2 then
            return convert~(RealDomain:-solve(_rest),radical);
        else
            error "未知调用方式";
        end if;
    end if;
end proc:

# 输出Delta
printDeltas:=proc(ds)
    map(i->print(Delta[i]=ds[i]),[seq(x,x=1..numelems(ds))]);
end proc:

$endif