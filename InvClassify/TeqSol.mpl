$ifndef _TEQ_SOL_
$define _TEQ_SOL_

$include "Utils.mpl"

TeqSol:=module()
    option object;
    export 
            rsol,           # 对应特解
            teq,            # 变换方程
            teqInd,
            tsols,          # 变换方程的解
            tcons,          # 解对应的条件

            printTsol::static,
            sortSols::static,
            getNSols::static,
            getRep::static,
            ModuleApply::static,    # 构造函数
            hasSol::static,         # 判断是否有解
            getCon::static;         # 给出最简约束条件
    
    ModuleApply:=proc(spec,ESC)
        local s,k;
        s:=Object(TeqSol);
        s:-rsol:=spec;
        s:-teq:=[ESC[1][1],ESC[2][1]];
        s:-teqInd:=[1$numelems(ESC[1][2]),2$numelems(ESC[2][2])];
        s:-tsols:=[ESC[1][2][],ESC[2][2][]];
        s:-tcons:=[ESC[1][3][],ESC[2][3][]];
        # sortSols(s);
        return s;
    end proc:

    hasSol:=proc(s::TeqSol)
        return ormap(x->evalb(x<>[]),s:-tsols);
    end proc:

    printTsol:=proc(s::TeqSol)
        local i,n:=numelems(s:-tsols);
        printf("=======================================\n");
        printf("特解\n");
        print(s:-rsol);
        printf("变换方程的解\n");
        for i from 1 to n do
            if s:-teqInd[i]=1 then
                printf("正向\n");
            else
                printf("逆向\n");
            end if;
            print(s:-tsols[i]);
            print(s:-tcons[i]);
        end do;
        printf("=======================================\n");
        return;
    end proc:

    # 对解进行排序
    # 有解的排在无解的前面
    # 约束条件少的排前面
    # 约束条件相同按复杂度排序
    sortSols:=proc(s::TeqSol)
        local ind,n;
        n:=numelems(s:-tsols);
        ind:=numelems~(s:-tcons)*n*10
            +sortByComplexity(s:-tcons,index)
            +map(x->`if`(x=[],1,0),s:-tsols)*n^2*100;
        ind:=sort(ind,output=permutation);
        s:-teqInd:=s:-teqInd[ind];
        s:-tsols:=s:-tsols[ind];
        s:-tcons:=s:-tcons[ind];
    end proc:

    getNSols:=proc(s::TeqSol)
        return numelems(s:-tsols);
    end proc:

    getRep:=proc(s::TeqSol)
        return add(v[i]*s:-rsol[i],i=1..numelems(s:-rsol));
    end proc:
    
end module:

$endif