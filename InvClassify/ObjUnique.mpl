ObjUnique:=module()
    option package;
    local   tassign,
            tappend;
    export  uniqueObj,
            collectObj;

    # 拓展键值 
    tappend:=proc(t,k,v)
        if assigned(t[k]) then
            t[k]:=t[k] union {v};
        else
            t[k]:={v};
        end if;
    end proc:

    # 对象按键值分类
    # 推荐对键做convert/global处理，以消除局部变量相等的问题。
    collectObj:=proc(s,key)
        local t,v;
        t:=table();
        for v in s do
            tappend(t,key(v),v);
        end do;
        return [entries(t,nolist)];
    end proc:

    # 对象按键值唯一化
    # 推荐对键做convert/global处理，以消除局部变量相等的问题
    uniqueObj:=proc(s,key)
        local t,v;
        t:=table();
        for v in s do
            t[key(v)]:=v;
        end do;
        return [entries(t,nolist)];
    end proc:
end module: