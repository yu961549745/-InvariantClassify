$ifndef _UTILS_
$define _UTILS_

tpop:=proc(t,k)
	local r;
	r:=t[k][1];
	t[k]:=t[k] minus {r};
	return r;
end proc:

# 表达式按照复杂度升序排序
sortByComplexity:=proc(_s::list,{index::boolean:=false})
    local s,t,i,n;
    if index then
        s:=_s;
        t:=table();
        n:=numelems(s);
        for i from 1 to n do
            tappend(t,s[i],i);
        end do;
        s:=ListTools[Reverse](SolveTools[SortByComplexity](s));
        return map[2](tpop,t,s);
    else
        return ListTools[Reverse](SolveTools[SortByComplexity](_s));
    end if;
end proc:

# 按照集合拓展table键值 
tappend:=proc(t,k,v)
    if assigned(t[k]) then
        t[k]:=t[k] union {v};
    else
        t[k]:={v};
    end if;
end proc:

# 对象按键值分类
# 推荐对键做convert/global处理，以消除局部变量相等的问题。
collectObj:=proc(s,key,{output:=[val]::{[ind],[val],[ind,val]}})
    local t,v,res;
    t:=table();
    for v in s do
        tappend(t,key(v),v);
    end do;
    res:=();
    if (ind in output) then
        res:=res,[indices(t,nolist)];
    end if;
    if (val in output) then
        res:=res,[entries(t,nolist)];
    end if;
    return res;
end proc:

# 对象按键值唯一化
# 推荐对键做convert/global处理，以消除局部变量相等的问题
uniqueObj:=proc(s,key,{index::boolean:=false})
    local t,i,n;
    t:=table();
    n:=numelems(s);
    for i from 1 to n do
        t[key(s[i])]:=`if`(index,i,s[i]);
    end do;
    return [entries(t,nolist)];
end proc:

# 选择目标函数值最小的元素
MinSelect:=proc(v::list,fun)
    return v[min[index]([seq(fun(x),x in v)])];
end proc:

$endif