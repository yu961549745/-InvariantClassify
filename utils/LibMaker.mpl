# 自定义生成包的工具。
# 基于LibraryTools。
# 增加了不存在包文件则直接创建文件的功能。
LibMaker:=module()
    option package;
    export MakeLib;

    (*
        将package保存到文件
        如果文件不存在则创建文件
        如果文件不含后缀名则补全后缀名
        默认文件名为 lib.mla
    *)
    MakeLib:=proc(mName,fName:="lib.mla")
        if not StringTools:-RegMatch(".*\\.mla",fName) then
            fName:=cat(fName,".mla");
        end if;
        if not FileTools:-Exists(fName) then
            LibraryTools:-Create(fName);
        end if;
        LibraryTools:-Save(mName,fNmae);
    end proc:
end module: