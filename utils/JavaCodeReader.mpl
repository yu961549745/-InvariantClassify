# 基于 CodeParser.jar 的代码读取包。
# 优点在于：
# 	1. 可以去除预处理器必须在行首的限制。
# 	2. include默认使用相对路径。
#	3. 可以指定文件编码。
# 缺点在于：
# 	1. jar文件的位置比较难搞，简单的做法放在项目的根目录下，
#		jar的相对目录和当前工作目录对应，
#		mla文件的相对目录也和当前工作目录对应，
#		所以不能简单的jar文件跟着mla走，代码中的位置需要调整。
JavaCodeReader:=module()
	option package;
	export ReadCode,ParseCode;
	
	ParseCode:=define_external(
		'parseCode',
		JAVA,CLASSPATH="./CodeParser.jar",
		CLASS="org.yjt.maple.CodeParser",
		'fin'::string,
		'fout'::string,
		'inputEncode'::string,
		'outputEncode'::string);

	ReadCode:=proc(fname::string,inEncode:="UTF8",outEncode:="UTF8")
		description "similar to `read`";
		local tmpFile;
		tmpFile:=cat(fname,".tmp.mpl");
		ParseCode(fname,tmpFile,inEncode,outEncode);
		read(tmpFile);
		FileTools[Remove](tmpFile);
	end proc:
end module: