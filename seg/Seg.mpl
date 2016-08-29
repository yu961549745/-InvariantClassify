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
            `+`::static,
            `-`::static,
            `*`::static,
            `^`::static,
            `ln`::static,
            `and`::static,
            `or`::static,
            `not`::static,
            simplify::static,
            bound;
    local   
            ModulePrint::static,
            ModuleApply::static,
            con2range::static,
            range2str::static,
            conBuild::static,
            expandRange::static,
            rangeBuild::static,
            rangeNot::static,
            sortOps::static,
            leftBound::static,
            `&+`::static,
            `&-`::static,
            rangeMax::static,
            rangeMin::static,
            `&plus`::static,
            calableRange::static;

    ModuleApply:=proc(x)
        if type(x,set({`=`,`<`,`<=`,`<>`})) then
            return conBuild(x);
        else
            return rangeBuild(x);
        end if;
    end proc:

    conBuild:=proc(cons::set({`=`,`<`,`<=`,`<>`}))
        local this,c;
        if numelems(indets(cons,name))<>1 
        or ormap(x->numelems(indets(cons,name))<>1,cons) then
            error "每个不等式（等式）都只能使用同一个变量";
        end if;
        this:=Object(Seg);
        this:-bound:=AndProp(con2range~(cons)[]);
        return this;
    end proc:

    rangeBuild:=proc(r)
        local this;
        this:=Object(Seg);
        this:-bound:=expandRange(r);
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

    `or`:=proc()
        option overload;
        return rangeBuild(OrProp(map(x->x:-bound,[_passed])[]));
    end proc:

    `not`:=proc(x::Seg,$)
        option overload;
        return rangeBuild(rangeNot(x:-bound));
    end proc:

    rangeNot:=proc(b)
        local lv,rv;
        if b=BottomProp then
            return RealRange(-infinity,infinity);
        elif type(b,extended_numeric) then
            return OrProp(RealRange(-infinity,Open(b)),RealRange(Open(b),infinity));
        elif b=real then
            return BottomProp;
        elif op(0,b)=RealRange then
            if op([1,0],b)=Open then
                lv:=op(1,b);
            else
                lv:=Open(op(1,b));
            end if;
            if op([2,0],b)=Open then
                rv:=op(2,b);
            else
                rv:=Open(op(2,b));
            end if;
            return OrProp(RealRange(-infinity,lv),RealRange(rv,infinity));
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
        elif type(b,extended_numeric) then
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
            return -infinity;
        elif type(b,extended_numeric) then
            return b;
        else
            return thisproc(op(1,b));
        end if;
    end proc:

    ModulePrint:=proc(x::Seg)
        local r:=range2str(x:-bound);
        if r[1]="<" then
            r:=r[3..-3];
        end if;
        r:=StringTools[SubstituteAll](r,"<","(");
        r:=StringTools[SubstituteAll](r,">",")");
        return r;
    end proc:

    rangeMin:=proc(b)
        if type(b,extended_numeric) then
            return b;
        elif op(0,b)=RealRange then
            return op(1,b);
        else
            error "未知调用方式";
        end if;
    end proc:

    rangeMax:=proc(b)
        if type(b,extended_numeric) then
            return b;
        elif op(0,b)=RealRange then
            return op(2,b);
        else
            error "未知调用方式";
        end if;
    end proc:

    `&plus`:=proc(x,y)
        if op(0,x)=Open or op(0,y)=Open then
            return Open(x+y);
        else
            return x+y;
        end if;
    end proc:

    calableRange:=proc(b)
        return type(b,extended_numeric) or op(0,b)=RealRange;
    end proc:

    `&+`:=proc(x,y)
        local z;
        if op(0,x)=OrProp then
            z:=OrProp(map[1](thisproc,[op(x)],y)[]);
        elif op(0,y)=OrProp then
            z:=OrProp(map[2](thisproc,x,[op(y)])[]);
        elif calableRange(x) and calableRange(y) then
            z:=RealRange(rangeMin(x) &plus rangeMin(y),rangeMax(x) &plus rangeMax(y));
        else
            error "未知调用方式";
        end if;
        if _rest=NULL then
            return z;
        else
            return thisproc(z,_rest);
        end if;
    end proc:
    
    `+`:=proc(x::Seg,y::Seg)
        option overload;
        local z;
        z:=rangeBuild(x:-bound &+ y:-bound);
        if _rest=NULL then
            return z;
        else
            return thisproc(z,_rest);
        end if;
    end proc:

    `&-`:=proc(x,$)
        if op(0,x)=OrProp then
            return OrProp(map(thisproc,[op(x)])[]);
        elif type(x,extended_numeric) then
            return -x;
        elif op(0,x)=Open then
            return Open(-op(x));
        elif op(0,x)=RealRange then
            return RealRange(&- op(2,x),&- op(1,x));
        else
            error "未知调用方式";
        end if;
    end proc:

    `-`:=proc(x::Seg,$)
        option overload;
        return rangeBuild(&- x:-bound);
    end proc:
end module:

$endif