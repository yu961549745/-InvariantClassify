tpop:=proc(t,k)
	local r;
	r:=t[k][1];
	t[k]:=t[k] minus {r};
	return r;
end proc:

# 表达式按照复杂度升序排序
sortByComplexity:=proc(_s::list,{index::boolean:=false})
    local s,t,i,n;
    if index then
        s:=_s;
        t:=table();
        n:=numelems(s);
        for i from 1 to n do
            tappend(t,s[i],i);
        end do;
        s:=ListTools[Reverse](SolveTools[SortByComplexity](s));
        return map[2](tpop,t,s);
    else
        return ListTools[Reverse](SolveTools[SortByComplexity](_s));
    end if;
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
collectObj:=proc(s,key,{output:=[val]::{[ind],[val],[ind,val]}})
    local t,v,res;
    t:=table();
    for v in s do
        tappend(t,key(v),v);
    end do;
    res:=();
    if (ind in output) then
        res:=res,[indices(t,nolist)];
    end if;
    if (val in output) then
        res:=res,[entries(t,nolist)];
    end if;
    return res;
end proc:

# 对象按键值唯一化
# 推荐对键做convert/global处理，以消除局部变量相等的问题
uniqueObj:=proc(s,key,{index::boolean:=false})
    local t,i,n;
    t:=table();
    n:=numelems(s);
    for i from 1 to n do
        t[key(s[i])]:=`if`(index,i,s[i]);
    end do;
    return [entries(t,nolist)];
end proc:

# 简要输出代表元及其成立条件以及不变量方程和变换方程的解
summaryReps:=proc()
    local i,n,r,_reps,id;
    _reps:=getReps();
    n:=numelems(_reps);
    for i from 1 to n do
        r:=_reps[i];
        printf("代表元 [%d]\n",i);
        print(r:-rep);
        printf("具有条件:\n");
        for id in r:-sid do
            print(getCon(r)[id]);
            print(r:-isol[id]);
            print(r:-tsol[id]);
            printf("-------------------------------------\n");
        end do;
    end do;
    return;
end proc:

# 简要输出代表元及其成立条件
printRepCon:=proc()
    map(x->print([x:-rep,getCon(x)[x:-sid]]),getReps()):
    return;
end proc:

# 输出Delta
printDeltas:=proc(ds)
    map(i->print(Delta[i]=ds[i]),[seq(x,x=1..numelems(ds))]);
end proc:
