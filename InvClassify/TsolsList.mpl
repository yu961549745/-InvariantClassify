$ifndef _TSOLS_LIST_
$define _TSOLS_LIST_

$include "Utils.mpl"

TsolsList:=module()
    option object;
    export
            reps,
            teqs,
            torders,
            tsols,
            tcons,
            ModuleApply::static,
            sortTsolsList::static,
            printTsolsList::static;

    ModuleApply:=proc(ss::list(TeqSol))
        local s;
        s:=Object(TsolsList);
        s:-reps:=map(x->getRep(x)$getNSols(x),ss);
        s:-teqs:=map(x->x:-teq[x:-teqInd][],ss);
        s:-torders:=map(x->x:-teqInd[],ss);
        s:-tsols:=map(x->x:-tsols[],ss);
        s:-tcons:=map(x->x:-tcons[],ss);
        sortTsolsList(s);
        return s;
    end proc:

    sortTsolsList:=proc(s::TsolsList)
        local ind,n:=numelems(s:-reps);
        ind:=map(x->`if`(x=[],1,0),s:-tsols)*n^3 # 有解的排在无解的前面
            +numelems~(s:-tcons)*n^2             # 约束条件少的排在前面
            +sortByComplexity(s:-tcons,index)*n; # 约束条件简单的排在前面
        ind:=sort(ind,output=permutation);
        s:-reps:=s:-reps[ind];
        s:-teqs:=s:-teqs[ind];
        s:-torders:=s:-torders[ind];
        s:-tsols:=s:-tsols[ind];
        s:-tcons:=s:-tcons[ind];
    end proc:

    printTsolsList:=proc(s::TsolsList)
        local i,n:=numelems(s:-reps);
        printf("============================================\n");
        for i from 1 to n do
            printf(`if`(s:-torders[i]=1,"正向\n","逆向\n"));
            print(s:-reps[i]);
            print(s:-tsols[i]);
            print(s:-tcons[i]);
        end do;
        printf("============================================\n");
        return;
    end proc:

end module:
$endif