# 以代表元为核心，进行合并、化简以及补全的工作
Combine:=module()
    option  package;
    local   reps:={};
    export  getReps,
            addReps,
            printReps,
            rmRep,
            updateRep,
            summary;
    local   formReps,
            completeRpes,
            combineReps,
            getSortedReps;

    # 获取合并化简后的代表元
    getReps:=proc(_sols)
        reps:=table();
        addReps(_sols);
        # 按照不变量方程进行排序输出
        return getSortedReps();
    end proc:

    # 获取排序后的reps
    getSortedReps:=proc()
        return sort([entries(eval(reps),nolist)],key=(x->[x:-osol[1]:-ieqCode,ModulePrint(x)]));
    end proc:

    # 增加代表元
    addReps:=proc(_sols)
        formReps(_sols);
        return getSortedReps();
    end proc:

    # 建立代表元变量
    # 同时将条件按复杂度排序
    # 现在是按照方程个数排序的
    formReps:=proc(_sols)
        local sols,r,ss,rep;
        sols:=select(x->evalb(x:-stateCode=5),_sols);# 只取求解成功的
        sols:=collectObj(sols,x->convert~(x:-rep,`global`));# 按代表元分类
        for ss in sols do
            rep:=convert(ss[1]:-rep,`global`);
            if assigned(reps[rep]) then
                r:=reps[rep];
            else
                r:=Object(RepSol);
                reps[rep]:=r;
            end if ;
            map[2](RepSol:-appendSol,r,ss);
            sortCon(r);
        end do;
        return;
    end proc:

    # 补全代表元
    completeRpes:=proc()
        return;
    end proc:

    # 合并不变量
    combineReps:=proc()
    end proc:

    # 查看所有rep
    printReps:=proc(reps)
        local i,n;
        n:=numelems(reps);
        for i from 1 to n do
            printf("代表元 [%d]---------------------------\n",i);
            printRep(reps[i]);
        end do;
    end proc:

    # 删除某个rep
    rmRep:=proc(r::RepSol)
        local rep;
        rep:=convert(r:-rep,`global`);
        reps[rep]:=evaln(reps[rep]);
    end proc:

    # 修改rep
    updateRep:=proc(r::RepSol)
        reps[convert(r:-rep,`global`)]:=r;
    end proc:

    # 显示所有rep的摘要
    summary:=proc()
        local i,n,r,_reps,id;
        _reps:=getSortedReps();
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
end module: