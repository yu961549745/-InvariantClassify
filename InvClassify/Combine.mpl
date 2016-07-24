Combine:=module()
    option  package;
    local   reps:={};
    export  getReps;
    local   formReps;

    # 获取合并化简后的代表元
    getReps:=proc(_sols)
        formReps(sols);
        return reps;
    end proc:

    # 建立代表元变量
    formReps:=proc(_sols)
        local sols,r,ss;
        sols:=select(x->evalb(x:-stateCode=5),_sols);# 只取求解成功的
        sols:=collectObj(sols,x->convert~(x:-rep,`global`));# 按不变量分类
        for ss in sols do
            r:=Object(RepSol);
            map[2](RepSol:-appendSol,r,ss);
            reps:=reps union {r};
        end do;
        return reps;
    end proc:
end module: