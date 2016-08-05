# 设置输出级别
setLogLevel:=proc(v::{1,2,3})
    logLevel:=v;
end proc:

flog:=proc()
    local v;
    if type(procname,indexed) then
        v:=op(procname);
    else
        v:=1;
    end if;
    if (v>=logLevel) then
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
    if (v>=logLevel) then
        printf(_passed);
    end if;
    return;
end proc: