(*

区间对象
实现运算：
    + 交集
    + 并集
    + 补集
    + 子集
实现了三种初始化方法：
    + 不等式集合
    + RealRange表达式
    + 区间的字符串表达形式
导出了辅助RealRange计算的两个函数

*)
$ifndef _SEG_
$define _SEG_

Seg:=module()
    option object;
    export
            # 运算符，优先级从高到低
            ## 逻辑版本
            `not`::static,          # 区间补集
            `and`::static,          # 区间交集
            `or`::static,           # 区间并集
            `xor`::static,          # 区间差集
            `implies`::static,      # 区间子集
            ## 集合版本
            `&C`::static,           # 区间补集
            `intersect`::static,    # 区间交集
            `union`::static,        # 区间并集
            `minus`::static,        # 区间差集
            `subset`::static,       # 区间属于

            # 属性
            bound:=real,            # 对应的 RealRange 对象

            # 导出工具函数
            formatRange::static,    # 将RealRange转化为区间表示形式
            evalRange::static;      # RealRange彻底求值
    local   
            # 初始化
            ModuleApply::static,    # 初始化
            conBuild::static,       # 使用约束集合初始化
            rangeBuild::static,     # 使用 RealRange 初始化
            con2range::static,      # 约束转化为 RealRange 对象
            strBuild::static,       # 使用字符串初始化
            exprOutput::static,     # 字符串解析辅助函数
            # 输出
            ModulePrint::static,    # 输出
            range2str::static,      # RealRange 对象转化为字符串
            sortOps::static,        # 输出时按左值排序
            leftBound::static,      # 获取 RealRange 左端值,用于排序
            # 计算
            expandRange::static,    # 化简 RealRange 对象
            subsRange::static,      # 替换Range表达式中的集合对象和Non表达式
            rangeNot::static;       # RealRange 对象取补集

    # 初始化
    ModuleApply:=proc(x)
        if type(x,set({`=`,`<`,`<=`,`<>`})) then
            return conBuild(x);
        elif type(x,string) then
            return strBuild(x);
        else
            return rangeBuild(x);
        end if;
    end proc:

    # 使用约束集合初始化
    conBuild:=proc(cons::set({`=`,`<`,`<=`,`<>`}))
        if numelems(indets(cons,name))<>1 
        or ormap(x->numelems(indets(cons,name))<>1,cons) then
            error "每个不等式（等式）都只能使用同一个变量";
        end if;
        return rangeBuild(AndProp(con2range~(cons)[]));
    end proc:

    # 使用 RealRange 初始化
    rangeBuild:=proc(r)
        local this;
        this:=Object(Seg);
        this:-bound:=evalRange(r);
        return this;
    end proc:

    # 将约束转化为RealRange
    con2range:=proc(_c::{`=`,`<`,`<=`,`<>`})
        local c,v;
        c:=RealDomain:-solve({_c})[];
        if type(c,`<`) then
            if type(lhs(c),numeric) then
                return RealRange(Open(lhs(c)),infinity);
            else
                return RealRange(-infinity,Open(rhs(c)));
            end if;
        elif type(c,`<=`) then
            if type(lhs(c),numeric) then
                return RealRange(lhs(c),infinity);
            else
                return RealRange(-infinity,rhs(c));
            end if;
        else
            if type(c,`=`) then
                return rhs(c);
            else
                v:=Open(rhs(c));
                return OrProp(RealRange(-infinity,v),RealRange(v,infinity));
            end if;
        end if;
    end proc:

    # 交集
    `and`:=proc()
        option overload;
        return rangeBuild(AndProp(map(x->x:-bound,[_passed])[]));
    end proc:
    `intersect`:=`and`;

    # 并集
    `or`:=proc()
        option overload;
        return rangeBuild(OrProp(map(x->x:-bound,[_passed])[]));
    end proc:
    `union`:=`or`;

    # 补集
    `not`:=proc(x::Seg,$)
        option overload;
        return rangeBuild(rangeNot(x:-bound));
    end proc:
    `&C`:=`not`;

    # 差集
    `xor`:=proc(x::Seg,y::Seg,$)
        return x and (not y);
    end proc:
    `minus`:=`xor`;

    # 子集
    `subset`:=proc(x::Seg,y::Seg,$)
        local z;
        z:=x and y;
        return evalb(z:-bound=x:-bound);
    end proc:
    `implies`:=`subset`;

    # RealRange彻底求值
    evalRange:=proc(x)
        return expandRange(subsRange(x));
    end proc:

    # RealRange补集展开
    rangeNot:=proc(b)
        local lv,rv,lb,rb;
        if b=BottomProp then
            return RealRange(-infinity,infinity);
        elif type(b,infinity) then
            return real;
        elif type(evalf(b),numeric) then
            return OrProp(RealRange(-infinity,Open(b)),RealRange(Open(b),infinity));
        elif b=real then
            return BottomProp;
        elif op(0,b)=RealRange then
            if op([1,0],b)=Open then
                lv:=op([1,1],b);
            else
                lv:=Open(op(1,b));
            end if;
            if op([2,0],b)=Open then
                rv:=op([2,1],b);
            else
                rv:=Open(op(2,b));
            end if;
            if has(lv,infinity) then
                lb:=NULL;
            else
                lb:=RealRange(-infinity,lv);
            end if;
            if has(rv,infinity) then
                rb:=NULL;
            else
                rb:=RealRange(rv,infinity);
            end if;
            return OrProp(lb,rb);
        elif op(0,b)=AndProp then
            return OrProp(thisproc~([op(b)])[]);
        elif op(0,b)=OrProp then
            return AndProp(thisproc~([op(b)])[]);
        end if;
    end proc:

    # 把 property 表达式中的集合都替换为 OrProp
    # 把 Non 展开
    subsRange:=proc(x)
        if type(x,set) then
            return OrProp(op(x));
        elif op(0,x)=Non then
            return rangeNot(op(x));
        elif op(0,x)=AndProp or op(0,x)=OrProp then
            return op(0,x)(thisproc~([op(x)])[]);
        else
            return x;
        end if;
    end proc:

    # 展开计算RealRange
    expandRange:=proc(x)
        local orv,nxt,rst,tmp;
        if op(0,x)=AndProp then
            # 所有的交集操作的返回结果都不应该表示为交集的形式
            if has([op(x)],OrProp) then
                # A⋂(B⋃C)=(A⋂B)⋃(A⋂C)
                orv:=op(1,x);
                nxt:=op(2,x);
                rst:=op(3..-1,x);
                tmp:=OrProp(map(x->AndProp(x,nxt),[op(orv)])[]);
                tmp:=AndProp(tmp,rst);
            elif type(op(1,x),extended_numeric) then
                # 计算 AndProp(x,property)
                # 因为集合已经被事先展开，所以这里只可能有一个数值对象
                # 而且经测试，顺序为：numeric < OrProp < RealRange
                if is(op(1,x),op(2,x)) then
                    tmp:=op(1,x);
                else
                    tmp:=BottomProp;
                end if;
            else
                tmp:=x;
            end if;
            return thisproc(tmp);
        elif op(0,x)=OrProp and has([op(x)],AndProp) then
        	return thisproc(OrProp(thisproc~([op(x)])[]));
        else
            return x;
        end if;
    end proc:

    # 将RealRange转化为区间表示形式
    range2str:=proc(b)
        local lc,lv,rc,rv,bs,r;
        if b=BottomProp then
            return "∅";
        elif type(evalf(b),extended_numeric) then
            return sprintf("{%a}",b);
        elif b=real then
            return "( -∞ , +∞ )";
        elif op(0,b)=RealRange then
            if op([1,0],b)=Open then
                lc:="(";
                lv:=op([1,1],b);
            else
                lc:="[";
                lv:=op(1,b);
            end if;
            if op([2,0],b)=Open then
                rc:=")";
                rv:=op([2,1],b);
            else
                rc:="]";
                rv:=op(2,b);
            end if;
            if type(lv,infinity) then
                lv:="-∞";
                lc:="(";
            else
                lv:=convert(lv,string);
            end if;
            if type(rv,infinity) then
                rv:="+∞";
                rc:=")";
            else
                rv:=convert(rv,string);
            end if;
            return sprintf("%s %s , %s %s",lc,lv,rv,rc);
        elif op(0,b)=OrProp then
            bs:=thisproc~(sortOps([op(b)]));
            r:=cat(map(x->cat(x," ⋃ "),bs)[]);
            return sprintf("< %s >",r[1..(-length(" ⋃ ")-1)]);
        elif op(0,b)=AndProp then
            bs:=thisproc~(sortOps([op(b)]));
            r:=cat(map(x->cat(x," ⋂ "),bs)[]);
            return sprintf("< %s >",r[1..(-length(" ⋂ ")-1)]);
        end if;
    end proc:

    # 用于排序
    sortOps:=proc(x)
        return sort(x,key=leftBound);
    end proc:

    # 区间左值
    leftBound:=proc(b)
        if b=BottomProp then
            return evalf(-infinity);
        elif type(evalf(b),extended_numeric) then
            return evalf(b);
        else
            return thisproc(op(1,b));
        end if;
    end proc:

    # 默认输出
    ModulePrint:=proc(x::Seg)
        return formatRange(x:-bound);
    end proc:

    # 将RealRange转化为区间表示形式
    formatRange:=proc(x)
        local r:=range2str(x);
        if r[1]="<" then
            r:=r[3..-3];
        end if;
        return r;
    end proc:

    # 根据区间的字符串表达形式初始化
    strBuild:=proc(_s::string)
        local r,s,cb,cx,cz,i,n,os,st,md,ed;
        s:=_s;
        # 处理无穷和交并符号
        s:=StringTools:-SubstituteAll(s,"\x26\x69\x6E\x66\x69\x6E\x3B","infinity");
        s:=StringTools:-SubstituteAll(s,"\x26\x62\x69\x67\x63\x61\x70\x3B","and");
        s:=StringTools:-SubstituteAll(s,"\x26\x62\x69\x67\x63\x75\x70\x3B","or");
        # 内部默认使用逻辑版本的运算符
        s:=StringTools:-SubstituteAll(s,"&C","not");
        s:=StringTools:-SubstituteAll(s,"intersect","and");
        s:=StringTools:-SubstituteAll(s,"union","or");
        s:=StringTools:-SubstituteAll(s,"minus","xor");
        s:=StringTools:-SubstituteAll(s,"subset","implies");
        # 解析字符串
        r:=StringTools:-StringBuffer();
        n:=length(s);
        cb:=0;# 区间括号标记
        cx:=0;# 小括号标记
        cz:=0;# 中括号标记
        os:=1;# 未处理的字符串的开始下标
        st:=0;# 区间开始下标
        md:=0;# 区间分隔符下标
        ed:=0;# 区间结束下标
        for i from 1 to n do
            if   s[i]="(" then
                if cx=0 and cb=0 then
                    cb:=1;
                    st:=i;
                else
                    cx:=cx+1;
                end if;
            elif s[i]="[" then
                if cz=0 and cb=0 then
                    cb:=1;
                    st:=i;
                else
                    cz:=cz+1;
                end if;
            elif s[i]="," and cb=1 and cx=0 and cz=0 then
            # 这么写保证了只有在其它表达式的()[]匹配的情况下才会将读取的`,`作为区间的分隔符，
            # 考虑到了其它表达式中出现`,`的可能性。
                md:=i;
            elif s[i]=")" then
                if cx=0 and cb=1 then
                    ed:=i;
                    cb:=0;
                    r:-append(exprOutput(s,os,st,md,ed));
                    os:=i+1;
                else
                    cx:=cx-1;
                end if;
            elif s[i]="]" then
                if cz=0 and cb=1 then
                    ed:=i;
                    cb:=0;
                    r:-append(exprOutput(s,os,st,md,ed));
                    os:=i+1;
                else
                    cz:=cz-1;
                end if;
            end if;
        end do;
        r:-append(s[os..-1]);
        s:=r:-value();
        r:-clear();
        # 处理单点区间
        s:=StringTools:-RegSubs("{(.*)}"="Seg({\\1})",s);
        # 处理括号
        s:=StringTools:-SubstituteAll(s,"<","(");
        s:=StringTools:-SubstituteAll(s,">",")");
        # 返回结果
        return eval(subs(Open(infinity)=infinity,Open(-infinity)=-infinity,parse(s)));
    end proc:

    # 辅助转化区间表达式为Maple表达式
    exprOutput:=proc(s,os,st,md,ed)
        local lv,rv,res;
        if s[st]="(" then
            lv:=sprintf("Open(%s)",s[(st+1)..(md-1)]);
        else
            lv:=s[(st+1)..(md-1)];
        end if;
        if s[ed]=")" then
            rv:=sprintf("Open(%s)",s[(md+1)..(ed-1)]);
        else
            rv:=s[(md+1)..(ed-1)];
        end if;
        res:=sprintf("%sSeg(RealRange(%s,%s))",s[os..(st-1)],lv,rv);
        return res;
    end proc:

end module:

$endif