# 基于Maple read 命令的代码读取包。
# 优点：
#     1. Maple原生支持，不需要额外的文件，直接被mla带走。
#     2. 不用产生临时文件。
# 缺点：
#     1. 预处理器必须在行首。
#     2. include的相对路径必须以 . 或 .. 开头。
#     3. 文档编码必须是UTF-8。
MapleCodeReader:=module()
    option package;
    export ReadCode;

    ReadCode:=proc(fname)
        local cd,p,f;
        p:=FileTools:-ParentDirectory(fname);
        f:=FileTools:-Filename(fname);
        cd:=currentdir();
        currentdir(p);
        read(f);
        currentdir(cd);
    end proc:
end module: