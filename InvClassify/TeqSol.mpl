$ifndef _TEQ_SOL_
$define _TEQ_SOL_

TeqSol:=module()
    option object;
    export 
            rsol:=[],               # 对应特解
            teq:=[[],[]],           # 变换方程
            tsols:=[[],[]],          # 变换方程的解
            tcons:=[[],[]],          # 解对应的条件

            printTsol::static,
            ModuleApply::static,    # 构造函数
            hasSol::static,         # 判断是否有解
            getCon::static;         # 给出最简约束条件
    
    ModuleApply:=proc(spec,ESC)
        local s,k;
        s:=Object(TeqSol);
        s:-rsol:=spec;
        for k from 1 to 2 do
            s:-teq[k]:= ESC[k][1];
            s:-tsols[k]:=ESC[k][2];
            s:-tcons[k]:=ESC[k][3];
        end do;
        return s;
    end proc:

    hasSol:=proc(s::TeqSol)
        return evalb( s:-tsols[1]<>[] or s:-tsols[2]<>[] );
    end proc:

    printTsol:=proc(s::TeqSol)
        printf("变换方程1\n");
        print(s:-tsols[1]);
        print(s:-tcons[1]);
        printf("变换方程2\n");
        print(s:-tsols[2]);
        print(s:-tcons[2]);
    end proc:
    
end module:

$endif