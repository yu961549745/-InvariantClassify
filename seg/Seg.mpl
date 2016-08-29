(*

区间对象
实现：
+ 基本操作
    + 利用不等式初始化
    + 交集
    + 并集
    + 补集
+ 计算值域：实现 + - * ^ ln 的值域计算

*)
$ifndef _SEG_
$define _SEG_

Seg:=module()
    option object;
    export
            `and`::static,          # 区间交集
            `intersect`::static,    # 区间交集
            `or`::static,           # 区间并集
            `union`::static,        # 区间并集
            `not`::static,          # 区间补集
            `minus`::static,        # 区间差集
            `subset`::static,       # 区间属于
            formatRange::static,    # 将RealRange转化为区间表示形式
            bound;                  # 对应的 RealRange 对象
    local   
            # 初始化
            ModuleApply::static,    # 初始化
            conBuild::static,       # 使用约束集合初始化
            rangeBuild::static,     # 使用 RealRange 初始化
            con2range::static,      # 约束转化为 RealRange 对象
            # 输出
            ModulePrint::static,    # 输出
             range2str::static,      # RealRange 对象转化为字符串
            sortOps::static,        # 输出时按左值排序
            leftBound::static,      # 获取 RealRange 左端值,用于排序
            # 计算
            expandRange::static,    # 化简 RealRange 对象
            rangeNot::static;       # RealRange 对象取补集

    ModuleApply:=proc(x)
        if type(x,set({`=`,`<`,`<=`,`<>`})) then
            return conBuild(x);
        else
            return rangeBuild(x);
        end if;
    end proc:

    conBuild:=proc(cons::set({`=`,`<`,`<=`,`<>`}))
        if numelems(indets(cons,name))<>1 
        or ormap(x->numelems(indets(cons,name))<>1,cons) then
            error "每个不等式（等式）都只能使用同一个变量";
        end if;
        return rangeBuild(AndProp(con2range~(cons)[]));
    end proc:

    rangeBuild:=proc(r)
        local this;
        this:=Object(Seg);
        this:-bound:=expandRange(subs(Non=rangeNot,r));
        return this;
    end proc:

    con2range:=proc(c::{`=`,`<`,`<=`,`<>`})
        local v;
        if type(c,{`<`,`<=`}) then
            return op(2,convert(c,RealRange));
        else
            if type(c,`=`) then
                return rhs(c);
            else
                v:=Open(rhs(c));
                return OrProp(RealRange(-infinity,v),RealRange(v,infinity));
            end if;
        end if;
    end proc:

    `and`:=proc()
        option overload;
        return rangeBuild(AndProp(map(x->x:-bound,[_passed])[]));
    end proc:

    `intersect`:=`and`;

    `or`:=proc()
        option overload;
        return rangeBuild(OrProp(map(x->x:-bound,[_passed])[]));
    end proc:

    `union`:=`or`;

    `not`:=proc(x::Seg,$)
        option overload;
        return rangeBuild(rangeNot(x:-bound));
    end proc:

    `minus`:=proc(x::Seg,y::Seg,$)
        return x and (not y);
    end proc:

    `subset`:=proc(x::Seg,y::Seg,$)
        local z;
        z:=x and y;
        return evalb(z:-bound=x:-bound);
    end proc:

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

    expandRange:=proc(x)
        local orv,nxt,rst,tmp;
        if op(0,x)=AndProp and has([op(x)],OrProp) then
            orv:=op(1,x);
            nxt:=op(2,x);
            rst:=op(3..-1,x);
            tmp:=OrProp(map(x->AndProp(x,nxt),[op(orv)])[]);
            tmp:=AndProp(tmp,rst);
            return thisproc(tmp);
        elif op(0,x)=OrProp and has([op(x)],AndProp) then
        	  return thisproc(OrProp(thisproc~([op(x)])[]));
        else
            return x;
        end if;
    end proc:

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

    sortOps:=proc(x)
        return sort(x,key=leftBound);
    end proc:

    leftBound:=proc(b)
        if b=BottomProp then
            return evalf(-infinity);
        elif type(evalf(b),extended_numeric) then
            return evalf(b);
        else
            return thisproc(op(1,b));
        end if;
    end proc:

    ModulePrint:=proc(x::Seg)
        return formatRange(x:-bound);
    end proc:

    formatRange:=proc(x)
        local r:=range2str(x);
        if r[1]="<" then
            r:=r[3..-3];
        end if;
        return r;
    end proc:

end module:

$endif