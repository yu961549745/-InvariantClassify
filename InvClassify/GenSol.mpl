$ifndef _GEN_SOL_
$define _GEN_SOL_

$include "Utils.mpl"

# 寻找一般解,考虑存在常数约束和多个单变量非零约束
# 若只存在一个极大元，则直接返回下标
# 否则分组返回极大元，相等的极大元放在一组中
findGenSolInd:=proc(icons::list(set),n::posint)
    return findGenVec(con2vec~(icons,n));
end proc:

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
    local mInd,i,j,n,isAdd,ind,t;
    n:=numelems(v);
    mInd:=table();
    mInd[1]:=1;
    for i from 2 to n do
        isAdd:=true;
        for j in indices(mInd,nolist) do
            if v[i] &> v[j] then
                unassign(evaln(mInd[j]));
            elif v[j] &> v[i]  then
                isAdd:=false;
                break;
            end if;
        end do;
        if isAdd then
            mInd[i]:=1;
        end if;
    end do;
    ind:=[indices(mInd,nolist)];
    if numelems(ind)=1 then
        return ind[1];
    else
        # 分组返回，相等的元素放在一组
        t:=table();
        for i in ind do
            tappend(t,v[i],i);
        end do;
        return [entries(t,nolist)];
    end if 
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