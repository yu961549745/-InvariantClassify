# 交互式求解函数

$ifndef _INTERACTION_
$define _INTERACTION_

# 添加新的RepSol进行求解
resolveRep:=proc(rep,solInd,{newIsol:=[],newRep:=[],nocheck::boolean:=false})
    return resolveSol(rep:-osol[solInd],_options);
end proc:

# 添加新的InvSol进行求解
resolveSol:=proc(sol::InvSol,{newIsol:=[],newRep:=[],nocheck::boolean:=false})
    local s,nreps;
    if (newIsol=[]) and (newRep=[]) then
        error "至少设置newIsol和newRep之一的值";
    end if;
    s:=Object(sol);
    if (newIsol<>[]) then
        setIsol(s,newIsol,_options['nocheck']);
    end if;
    if (newRep<>[]) then
        setRep(s,newRep,_options['nocheck']);
    end if;
    resolve(s);
    nreps:=addReps(getNewSols());
    printf("新产生代表元:");
    printReps(nreps);
    return nreps;
end proc:

# 获取新的代表元
fetchNewRep:=proc(rep,solInd,con)
    return fetchSolRep(rep:-osol[solInd],addcon=con);
end proc:

# 检查两个代表元之间能否相互转化
canTransform:=proc(r1,i1,r2,i2)
    local s1,s2,eqs;
    s1:=r1:-osol[i1];
    s2:=r2:-osol[i2];
    eqs:=table();
    eqs[1]:=testTransform(s1,s2,s1);
    if (eqs[1]=true) then
        return true;
    end if;
    eqs[2]:=testTransform(s1,s2,s2);
    if (eqs[2]=true) then
        return true;
    end if;
    eqs[3]:=testTransform(s2,s1,s1);
    if (eqs[3]=true) then
        return true;
    end if;
    eqs[4]:=testTransform(s2,s1,s2);
    if (eqs[4]=true) then
        return true;
    end if;
    printf("无法求解变换方程");
    print~([entries(eqs,nolist)]);
    return false;
end proc:

# 检查两个解之间能否相互转化
# TODO　这里没有考虑转化是否有成立的条件
testTransform:=proc(s1,s2,base)
    local eq,sol,con;
    eq,sol,con:=solveTeq(s1:-rvec,s2:-rvec,base);
    if (sol<>[]) then
        print(s2:-rep);
        printf("可以在");
        print(base:-isol);
        printf("下，通过");
        print(sol);
        printf("转化为");
        print(s1:-rep);
        return true;
    else
        return eq;
    end if;
end proc:

# 输出所有InvSol对象
printSols:=proc(sols)
    local n,i;
    n:=numelems(sols);
    for i from 1 to n do
        printf("---------------------------------------------------------");
        printf("sols[%d]",i);
        printSol(sols[i]);
    end do;
    return sols;
end proc:

# 输出所有RepSol对象
printReps:=proc(reps)
    local i,n;
    n:=numelems(reps);
    for i from 1 to n do
        printf("代表元 [%d]---------------------------",i);
        printRep(reps[i]);
    end do;
end proc:

# 简要输出代表元及其成立条件
printRepCon:=proc()
    map(x->print([x:-rep,getCon(x)[x:-sid]]),getReps()):
    return;
end proc:

# 简要输出代表元及其成立条件以及不变量方程和变换方程的解
summaryReps:=proc()
    local i,n,r,_reps,id;
    _reps:=getReps();
    n:=numelems(_reps);
    for i from 1 to n do
        r:=_reps[i];
        printf("代表元 [%d]",i);
        print(r:-rep);
        printf("具有条件:");
        for id in r:-sid do
            print(getCon(r)[id]);
            print(r:-isol[id]);
            print(r:-tsol[id]);
            printf("-------------------------------------");
        end do;
    end do;
    return;
end proc:

$endif