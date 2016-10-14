$ifndef _LOGOUT_
$define _LOGOUT_

LogLevelHolder:=module()
    option object;
    export logLevel:=1;
end module:

# 设置输出级别
setLogLevel:=proc(v::{0,1,2,3})
    LogLevelHolder:-logLevel:=v;
    return;
end proc:

flog:=proc()
    local v;
    if type(procname,indexed) then
        v:=op(procname);
    else
        v:=1;
    end if;
    if (v>=LogLevelHolder:-logLevel) then
        print(_passed);
    end if;
    return;
end proc:

flogf:=proc()
    local v;
    if type(procname,indexed) then
        v:=op(procname);
    else
        v:=1;
    end if;
    if (v>=LogLevelHolder:-logLevel) then
        printf(_passed);
        printf("\n");
    end if;
    return;
end proc:

$endif