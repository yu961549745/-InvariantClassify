find:=proc(v::list,k)
    return map(i->`if`(v[i]=k,i,NULL),[seq(1..numelems(v))]);
end proc:
find([0,1,0,1,1],1);