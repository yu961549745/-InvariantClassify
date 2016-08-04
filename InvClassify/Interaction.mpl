# 交互式求解函数

# 添加新的RepSol进行求解
resolveRep:=proc(rep,solInd,{newIsol:=[],newRep:=[],nocheck::boolean:=false})
    return resolveSol(rep:-osol[solInd],_options);
end proc:

# 添加新的InvSol进行求解
resolveSol:=proc(sol::InvSol,{newIsol:=[],newRep:=[],nocheck::boolean:=false})
    local s,nreps;
    if evalb(newIsol=[]) and evalb(newRep=[]) then
        error "至少设置newIsol和newRep之一的值";
    end if;
    s:=Object(sol);
    if evalb(newIsol<>[]) then
        setIsol(s,newIsol,_options['nocheck']);
    end if;
    if evalb(newRep<>[]) then
        setRep(s,newRep,_options['nocheck']);
    end if;
    resolve(s);
    nreps:=addReps(getNewSols());
    printf("新产生代表元:\n");
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
    if evalb(eqs[1]=true) then
        return true;
    end if;
    eqs[2]:=testTransform(s1,s2,s2);
    if evalb(eqs[2]=true) then
        return true;
    end if;
    eqs[3]:=testTransform(s2,s1,s1);
    if evalb(eqs[3]=true) then
        return true;
    end if;
    eqs[4]:=testTransform(s2,s1,s2);
    if evalb(eqs[4]=true) then
        return true;
    end if;
    printf("无法求解变换方程\n");
    print~([entries(eqs,nolist)]);
    return false;
end proc:

# 检查两个解之间能否相互转化
testTransform:=proc(s1,s2,base)
    local eq,sol,con;
    eq,sol,con:=solveTeq(s1:-rvec,s2:-rvec,base);
    if evalb(sol<>[]) then
        print(s2:-rep);
        printf("可以在\n");
        print(base:-isol);
        printf("下，通过\n");
        print(sol);
        printf("转化为\n");
        print(s1:-rep);
        return true;
    else
        return eq;
    end if;
end proc: