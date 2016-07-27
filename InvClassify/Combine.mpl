# 以代表元为核心，进行合并、化简以及补全的工作


# 重新建立代表元
buildReps:=proc(_sols)
    reps:=table();
    addReps(_sols);
    # 按照不变量方程进行排序输出
    return getReps();
end proc:

# 获取排序后的reps
getReps:=proc()
    return sort([entries(eval(reps),nolist)],key=(x->[x:-osol[1]:-ieqCode,ModulePrint(x)]));
end proc:

# 增加代表元
addReps:=proc(_sols)
    local inds;
    inds:=formReps(_sols);
    return map(x->reps[x],inds);
end proc:

# 建立代表元变量
# 同时将条件按复杂度排序
# 现在是按照方程个数排序的
formReps:=proc(_sols)
    local sols,r,ss,rep,inds;
    sols:=select(x->evalb(x:-stateCode=5),_sols);# 只取求解成功的
    inds,sols:=collectObj(sols,x->getRep(x),output=[ind,val]);# 按代表元分类
    for ss in sols do
        rep:=getRep(ss[1]);
        if assigned(reps[rep]) then
            r:=reps[rep];
        else
            r:=Object(RepSol);
            reps[rep]:=r;
        end if ;
        map[2](RepSol:-appendSol,r,ss);
        sortCon(r);
    end do;
    return inds;
end proc:

# 删除某个rep
rmRep:=proc(r::RepSol)
    local rep;
    rep:=getRep(r:-osol[1]);
    if assigned(reps[rep]) then
        reps[rep]:=evaln(reps[rep]);
    end if;
    return NULL;
end proc:

# 修改rep
updateRep:=proc(r::RepSol)
    reps[getRep(r:-osol[1])]:=r;
end proc:
