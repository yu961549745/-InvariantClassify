$ifndef _GEN_SOL_
$define _GEN_SOL_

# 将约束条件转化为向量
con2vec:=proc(c::set,n::posint)
    local v,t;
    v:=Array(1..n,2);
    for t in c do
        if op(0,t)=`=` then
            v[op([1,1],indets(t,name))]:=0;
        elif op(0,t)=`<>` then
            v[op([1,1],indets(t,name))]:=1;
        end if;
    end do;
    return convert(v,list);
end proc:

# 寻找一般解
# 等价于寻找偏序集的极大元
# 返回下标的list
findGenVec:=proc(v::list)
    local mInd,i,j,n,isAdd;
    n:=numelems(v);
    mInd:=table();
    mInd[1]:=1;
    for i from 2 to n do
        isAdd:=true;
        for j in indices(mInd,nolist) do
            if v[i] &>= v[j] then
                if v[i] &> v[j] then
                    unassign(evaln(mInd[j]));
                else
                    # 相等则添加
                end if;
            elif v[j] &>= v[i]  then
                if v[j] &> v[i] then
                    # 小于则不添加
                    isAdd:=false;
                    break;
                else
                    # 相等则添加
                end if;
            else
            end if;
        end do;
        if isAdd then
            mInd[i]:=1;
        end if;
    end do;
    return [indices(mInd,nolist)];
end proc:

`&>=`:=proc(x::list,y::list)
    local n:=numelems(x);
    return andmap(k->evalb(x[k]>=y[k]),[seq(1..n)]);
end proc:

`&>`:=proc(x::list,y::list)
    local n:=numelems(x);
    return x &>= y and ormap(k->evalb(x[k]>y[k]),[seq(1..n)]);
end proc:

$endif