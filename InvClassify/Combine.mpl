# 以代表元为核心，进行合并、化简以及补全的工作
Combine:=module()
    option  package;
    local   reps:={};
    export  getReps;
    local   formReps,
            setSimple,
            completeRpes,
            combineReps;

    # 获取合并化简后的代表元
    getReps:=proc(_sols)
        reps:={};
        formReps(_sols);
        setSimple~(reps);
        return reps;
    end proc:

    # 建立代表元变量
    formReps:=proc(_sols)
        local sols,r,ss;
        sols:=select(x->evalb(x:-stateCode=5),_sols);# 只取求解成功的
        sols:=collectObj(sols,x->convert~(x:-rep,`global`));# 按代表元分类
        for ss in sols do
            r:=Object(RepSol);
            map[2](RepSol:-appendSol,r,ss);
            reps:=reps union {r};
        end do;
        return;
    end proc:

    # 选择最简条件，以及对应的解
    setSimple:=proc(_rep)
        return;
    end proc:

    # 补全代表元
    completeRpes:=proc()
        return;
    end proc:

    # 合并不变量
    combineReps:=proc()
    end proc:
end module: