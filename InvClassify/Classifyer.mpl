classify:=proc(A,As,eqs)
    local sol;
    sols:={};
    usols:=table();
    oldSols:={};
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
    oldSols:=sols;
    return sort([sols[]],'key'=(x->[x:-ieqCode,convert(getDesc(x),`global`)]));
end proc:

# 获取新增的代表元
# 新的代表元只能获取一次
getNewSols:=proc()
    local res;
    res:=sort([ (sols minus oldSols)[] ],'key'=(x->x:-ieqCode));
    oldSols:=sols;
    return res;
end proc:

getCname:=proc()
    cid:=cid+1;
    return c[cid];
end proc:

getIeqCode:=proc()
    ieqCode:=ieqCode+1;
    return ieqCode;
end proc:

resolve:=proc(sol::InvSol)
    local spos,pos,nDelta,_usols,_usol,oldDeltas,oldSol;
    
    if evalb(sol:-stateCode=1) then
        # 尝试求解偏微分方程组
        # 如果所有方程组为空，则停止求解
        if evalb(sol:-oeq={}) then
            return;
        end if;
        nDelta:=getInvariants(sol:-oeq);
        # 求解失败
        if evalb(indets(nDelta,name) intersect {seq(a[i],i=1..sol:-nvars)} = {}) then
            # 求解失败不添加解
            # 不考虑不能求解不变量的情况
            return "新不变量求解失败";
        end if;
        # 设置新的不变量
        spos:=numelems(sol:-Delta)+1;
        oldDeltas:={sol:-Delta[]};
        oldSol:=Object(sol);
        if evalb(sol:-Delta<>[]) then
            sol:-Delta:=[sol:-Delta[],nDelta[]]:
            # 整体化简不变量
            if evalb(1>=logLevel) then
                flogf[1]("-----------------------------------------------\n");
                flogf[1]("对新增不变量按照原不变量进行化简\n");
                flogf[1]("化简前\n");
                printDeltas(sol:-Delta);
                sol:-Delta:=simplifyInvariants(sol:-Delta);
                flogf[1]("化简后\n");
                printDeltas(sol:-Delta);
            end if;
        else
            sol:-Delta:=[sol:-Delta[],nDelta[]]:
        end if;
        sol:-orders:=findInvariantsOrder~(sol:-Delta):# 计算不变量阶数
        # 根据新的不变量是否有约束来决定是否求解上一个全零方程
        nDelta:=remove(x->evalb(x in oldDeltas),sol:-Delta);
        if evalb( `union`(findDomain~(nDelta)[]) <> {} ) and evalb(sol:-Delta<>[]) then
            solveRestAllZeroIeqs(oldSol);
        end if;
        # 建立和求解不变量方程组
        for pos from spos to numelems(sol:-Delta) do
            buildInvEqs(sol,pos);
        end do;
        # 生成新的不变量
        genInvariants(sol);
    elif evalb(sol:-stateCode=2) then
        # 求解不变量方程组
        solveInvEqs(sol);
    elif evalb(sol:-stateCode=3) then
        # 取代表元
        fetchRep(sol);
    elif evalb(sol:-stateCode=4) then
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
    # 阶数可能是分数
    # 不变量的次方还是不变量，直接看分子
    # 不过现在不变量化简那边已经加了这种化简规则
    if type(numer(_sol:-orders[pos]),even) then
        xpos:=[1,-1,0];
    else
        xpos:=[1,0];
    end if;
    # 生成方程右端
    cid:=0;
    rs:=Array(1..n,x->
    if evalb(x>pos) then
        getCname()
    else
        0
    end if);
    # 逐个方程求解
    for x in xpos do
        # 对于Delta[pos]=0，构建下一个方程进行求解
        # 不求解全零方程
        if evalb(x=0) then
            # 这里是每个全零方程都进行求解的意思
            # 否则直接next就好了
            if evalb(pos<>n) then
                next;
            else
                # 这里是直接求解
                # solveAllZero(_sol);
                
                # 这里是延后求解
                usols[getUsolsKey(_sol)]:=_sol;
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
    isols:=RealDomain:-solve(sol:-Delta,[seq(a[i],i=1..sol:-nvars)],explicit);
    # 全部求解失败，则求解上一个全零方程
    if andmap(isol->evalb(subsOeq(sol,isol)="新不变量求解失败"),isols) then
        solveRestAllZeroIeqs(sol);
    end if;
end proc:

# 生成新的不变量方程
# 这么写会导致和非自由变量有关的偏导都变成0
subsOeq:=proc(_sol::InvSol,isol)
    local oeq,sol,v,vv,vars,Delta;
    flogf[1]("--------------------------------------------------------------\n");
    flogf[1]("求解新的不变量\n");
    flog[1]({seq(Delta[i]=0,i=1..numelems(_sol:-Delta))});
    flog[2](getDisplayDelta(_sol));
    flogf[1]("取解\n");
    flog[1](isol);
    oeq:=_sol:-oeq;
    vars:=_sol:-vars;
    v,vv:=selectremove(x->evalb(lhs(x)<>rhs(x)),isol);
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
    isols:=RealDomain:-solve(_sol:-ieq,vars,explicit);
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
    isols:=RealDomain:-solve(sol:-Delta,var,explicit);
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
            flogf[1]("--------------------------------------------------------------\n");
            flogf[1]("求解全零方程\n");
            flog[1](getDisplayIeq(nnsol));
            flog[1](getDisplayDelta(nnsol));
            flogf[1]("取解\n");
            flog[1](nnsol:-isol);
            flogf[1]("具有约束条件\n");
            flog[1](nnsol:-icon);
            flogf[1]("取特解\n");
            flog[1](nnsol:-rvec);
            flogf[1]("取代表元\n");
            flog[1](nnsol:-rep);
            resolve(nnsol);
        end do;
    end do;
end proc:

# 取代表元
fetchRep:=proc(_sol::InvSol)
    local n,_ax;
    flogf[1]("--------------------------------------------------------------\n");
    flogf[1]("对于不变量方程\n");
    flog[1](getDisplayIeq(_sol));
    flog[1](getDisplayDelta(_sol));
    flogf[1]("取解\n");
    flog[1](_sol:-isol);
    flogf[1]("具有约束条件\n");
    flog[1](_sol:-icon);
    n:=_sol:-nvars;
    _ax:=fetchSolRep(_sol);
    if evalb(_ax=NULL) then# 取特解失败
        sols:=sols union {_sol};
        flogf[1]("取特解失败\n");
        return;
    end if;
    setRep(_sol,_ax);
    if evalb(_sol:-rep=0) then
        flogf[1]("代表元取0\n");
        return;
    end if;
    _ax:=Matrix(_ax);
    _sol:-stateCode:=4;
    flogf[1]("取特解\n");
    flog[1](convert(_ax,list));
    flogf[1]("取代表元\n");
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
    if andmap(x->evalb(x=[]),_sol:-tsol) then
        # 无解
        flogf[1]("变换方程求解失败\n");
        sols:=sols union {_sol};
    else
        # 有解
        flogf[1]("变换方程有解\n");
        _sol:-stateCode:=5;
        sols:=sols union {_sol};
        # 在logLevel为1时输出
        if evalb(1>=logLevel) then
            printTeq(_sol,1);
            printTeq(_sol,2);
        end if;
    end if;
    return;
end proc:

(*
    求解变换方程

    因为变换方程只关心其存在性，而不在乎其完整性，因此不用explicit选项，而采用convert/radical
*)
solveTeq:=proc(a,b,sol)
    local var,teq,tsol,tcon,scon,eqs,eq,_eq,_con,_sol;
    teq:=convert((a-b.sol:-A),list);
    teq:=subs(sol:-isol[],teq);
    var:=[seq(epsilon[i],i=1..sol:-nvars)];
    tsol:=convert~(RealDomain:-solve(teq,var),radical);
    if evalb(tsol=[]) then
        # 求解失败，尝试二次求解法方法
        # 首次求解
        eqs:=convert~([RealDomain:-solve(teq)],radical);
        # 二次求解
        tsol:=[];
        tcon:=[];
        for eq in eqs do
            _eq:=select(eqOfEpsilon,eq);
            _con:=remove(eqOfEpsilon,eq);
            _con:=remove(x->type(x,`=`) and evalb(lhs(x)=rhs(x)),_con);
            _sol:=convert~(RealDomain:-solve(_eq,var,explicit),radical);
            _con:=map(x->clearConditions(findSolutionDomain(x)) union _con,_sol);
            tsol:=[tsol[],_sol[]];
            tcon:=[tcon[],_con[]];
        end do;
    else
        # 求解成功，直接计算约束
        tcon:=map(x->clearConditions(findSolutionDomain(x)),tsol);
    end if;
    # 清理矛盾解
    tsol:=zip((s,c)->if evalb(undefined in rhs~(c)) then NULL else s end if,tsol,tcon);
    tcon:=remove(c->evalb(undefined in rhs~(c)),tcon);
    return teq,tsol,tcon;
end proc:

eqOfEpsilon:=proc(eq)
    return ormap(x->type(x,specindex(epsilon)),indets(eq,name));
end proc:

# 删除与a无关的约束
clearConditions:=proc(con)
    return select(x->ormap(type,indets(x,name),specindex(a)),con);
end proc:

# 求解剩余全零不变量方程
solveRestAllZeroIeqs:=proc(sol::InvSol)
    solveAllZero( usols[getUsolsKey(sol)] );
end proc:

# 获取全零不变量方程在usols中的key
getUsolsKey:=proc(sol)
    return convert([seq(Delta[i],i=1..numelems(sol:-Delta))],`global`);
end proc: