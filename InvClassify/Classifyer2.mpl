$ifndef _CLASSIFYER_
$define _CLASSIFYER_

$include "Basic.mpl"
$include "Condition.mpl"
$include "Fetch.mpl"
$include "InvOrder.mpl"
$include "InvSimplify.mpl"
$include "Logout.mpl"
$include "Utils.mpl"
$include "InvSol2.mpl"

ClassifyHolder:=module()
    local   cid,ieqCode,sols;
    export  reset,      # 重置状态
            addSol,     # 新增解
            getSols,    # 获取解
            getIeqCode, # 获取不变量方程的编号
            getCname;   # 获取常数变量的名字
    
    reset:=proc()
        cid:=0;
        ieqCode:=0;
        sols:={};
        return;
    end proc:

    addSol:=proc(s::InvSol)
        sols:=sols union {s};
        return;
    end proc:

    getSols:=proc()
        return sols;
    end proc:

    getCname:=proc()
        cid:=cid+1;
        return c[cid];
    end proc:

    getIeqCode:=proc()
        ieqCode:=ieqCode+1;
        return ieqCode;
    end proc:

end module:

# 绑定函数
reset:=ClassifyHolder:-reset;
addSol:=ClassifyHolder:-addSol;
getSols:=ClassifyHolder:-getSols;
getCname:=ClassifyHolder:-getCname;
getIeqCode:=ClassifyHolder:-getIeqCode;


# 重新求解的入口
classify:=proc(As,A,eqs)
    local sol;
    sol:=Object(InvSol);
    sol:-As:=As;
    sol:-A:=A;
    sol:-oeq:=eqs;
    sol:-state:=0;
    sol:-addCons:={};
    reset();
    resolve(sol);
end proc:

# 可重用的求解入口
resolve:=proc(s::InvSol)
    local nDeltas;
    if   (s:-state=0) then
        # 求解新的不变量
        nDeltas:=getNewInvariants(s);
        sol:=Object(s);
        sol:-Deltas:=[sol:-Deltas[],nDeltas[]];
        
    elif (s:-state=1) then
        # 建立和不变量方程
    elif (s:-state=2) then
        # 求解不变量方程
    elif (s:-state=3) then
        # 取代表元
    elif (s:-state=4) then
        # 求解变换方程
    end if;
end proc:

getNewInvariants:=proc(s::InvSol)
    local oeq,deltas;

    flogf[1]("-------------------------------------------------\n");
    flogf[1]("求解新的不变量\n");
    flogf[1]("附加约束\n");
    flog[1](s:-addCons);

    oeq:=remove(type,subs(s:-addCons[],s:-oeq),0);
    flogf[1]("偏微分方程组\n");
    flog[1](oeq);

    # 求解新不变量（已化简）
    deltas:=getInvariants(oeq);

    # 检查是否有解
    if not type(indets(deltas,name),set(specindex(a))) then
        deltas:=[];
    end if; 

    return deltas;
end proc:

$endif