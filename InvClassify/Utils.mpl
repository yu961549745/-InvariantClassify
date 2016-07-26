# 表达式按照复杂度升序排序
sortByComplexity:=proc(s::list)
    return ListTools[Reverse](SolveTools[SortByComplexity](s));
end proc:

# 输出所有InvSol对象
printSols:=proc(sols::list(InvSol))
    local n,i;
    n:=numelems(sols);
    for i from 1 to n do
        printf("---------------------------------------------------------\n");
        printf("sols[%d]\n",i);
        printSol(sols[i]);
    end do;
    return sols;
end proc:

# 输出所有RepSol对象
printReps:=proc(reps)
    local i,n;
    n:=numelems(reps);
    for i from 1 to n do
        printf("代表元 [%d]---------------------------\n",i);
        printRep(reps[i]);
    end do;
end proc:

# 按照集合拓展table键值 
tappend:=proc(t,k,v)
    if assigned(t[k]) then
        t[k]:=t[k] union {v};
    else
        t[k]:={v};
    end if;
end proc:

# 对象按键值分类
# 推荐对键做convert/global处理，以消除局部变量相等的问题。
collectObj:=proc(s,key)
    local t,v;
    t:=table();
    for v in s do
        tappend(t,key(v),v);
    end do;
    return [entries(t,nolist)];
end proc:

# 对象按键值唯一化
# 推荐对键做convert/global处理，以消除局部变量相等的问题
uniqueObj:=proc(s,key)
    local t,v;
    t:=table();
    for v in s do
        t[key(v)]:=v;
    end do;
    return [entries(t,nolist)];
end proc: