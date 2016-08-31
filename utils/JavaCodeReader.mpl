# 基于 CodeParser.jar 的代码读取包。
# 优点在于：
# 	1. 可以去除预处理器必须在行首的限制。
# 	2. include默认使用相对路径。
#	3. 可以指定文件编码。
#	4. 默认每个文件只会include一遍。
# 注：会自动在 libname 包含的目录下寻找jar文件。
JavaCodeReader:=module()
	option  package;
	export 	ReadCode,ParseCode;
	local  	parseCode,
			parseStr,
			ModuleLoad;

	ModuleLoad:=proc()
		local jarName,jarPath,path,isFinded:=false;
		jarName:="CodeParser.jar";
		for path in :-libname do
			jarPath:=FileTools:-JoinPath([path,jarName]);
			if FileTools:-Exists(jarPath) then
				isFinded:=true;
				break;
			end if;
		end do;
		if not isFinded then
			error "找不到 %1 ，请确保 %2 下存在该文件。",jarName,[libname];
		end if;
		parseCode:=define_external(
			'mapleCall',
			JAVA,CLASSPATH=jarPath,
			CLASS="org.yjt.maple.ParseCodeUtil",
			'fin'::string,
			'fout'::string,
			'inputEncode'::string,
			'outputEncode'::string);
	end proc:
	ModuleLoad();

	# 采用Base64编码传递文件路径以支持中文
	# 注意Maple内部字符串的编码为UTF8
	parseStr:=proc(s::string)
		return StringTools:-Encode(s,'encoding'='base64');
	end proc:

	ParseCode:=proc(fin::string,fout::string,inEncode:="UTF8",outEncode:="UTF8")
		parseCode(parseStr(fin),parseStr(fout),inEncode,outEncode);
	end proc:

	ReadCode:=proc(fname::string,inEncode:="UTF8",outEncode:="UTF8")
		description "similar to `read`";
		local tmpFile;
		tmpFile:=cat(fname,".tmp.mpl");
		ParseCode(fname,tmpFile,inEncode,outEncode);
		read(tmpFile);
		FileTools[Remove](tmpFile);
		return;
	end proc:
end module: