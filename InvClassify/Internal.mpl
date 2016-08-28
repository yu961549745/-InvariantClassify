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
$ifndef _INTERNAL_
$define _INTERNAL_

Bound:=module()
    option  object;
    export  `&and`::static,
            isIntersected::static,
            `&or`::static,
            bound2str::static,
            isNull::static,
            notNull::static;
    local   ModuleApply::static,
            ModulePrint::static,
            lb,ub,lc,uc;

    ModuleApply:=proc(b,c)
        local obj;
        obj:=Object(Bound);
        obj:-lb:=b[1];
        obj:-ub:=b[2];
        obj:-lc:=c[1];
        obj:-uc:=c[2];
        return obj;
    end proc:

    bound2str:=proc(x::Bound)
        local l,r,lv,rv;
        l:=`if`(x:-lc,`[ `,`( `);
        r:=`if`(x:-uc,` ]`,` )`);
        lv:=`if`(type(x:-lb,infinity),"-∞",convert(x:-lb,string));
        rv:=`if`(type(x:-ub,infinity),"∞",convert(x:-ub,string));
        return sprintf("%s%s , %s%s",l,lv,rv,r);
    end proc:

    ModulePrint:=proc(x::Bound)
        return bound2str(x);
    end proc:

    notNull:=proc(x::Bound)
        if x:-lb<x:-ub then
            return true;
        elif x:-lb>x:-ub then
            return false;
        else
            return x:-lc and x:-uc;
        end if;
    end proc:

    isNull:=proc(x::Bound)
        return not notNull(x);
    end proc:

    `&and`:=proc(x::Bound,y::Bound)
        local lb,ub,lc,uc;
        if x:-lb<y:-lb then
            lb:=y:-lb;
            lc:=y:-lc;
        elif x:-lb>y:-lb then
            lb:=x:-lb;
            lc:=x:-lc;
        else
            lb:=x:-lb;
            lc:=:-`and`(x:-lb,y:-lb);
        end if;
        if x:-ub>y:-ub then
            ub:=y:-ub;
            uc:=y:-uc;
        elif x:-ub<y:-ub then
            ub:=x:-ub;
            uc:=x:-uc;
        else
            ub:=x:-ub;
            uc:=:-`and`(x:-ub,y:-ub);
        end if;
        return Bound([lb,ub],[lc,uc]);
    end proc:

    isIntersected:=proc(x::Bound,y::Bound)
        return notNull(x &and y);
    end proc:

    `&or`:=proc(_x::Bound,_y::Bound)
        local x,y;
        # 保证 x:-lb <= y:-lb
        if _x:-lb <= _y:-lb then
            x:=_x;
            y:=_y;
        else
            x:=_y;
            y:=_x;
        end if;
        # 区间并集
        if x:-ub < y:-lb then
            return x,y;
        elif x:-ub > y:-lb then
            return Bound([x:-lb,y:-ub],[x:-lc,y:-uc]);
        else
            if x:-uc or y:-lc then
                return Bound([x:-lb,y:-ub],[x:-lc,y:-uc]);
            else
                return x,y;
            end if;
        end if;
    end proc:
end module:

Internal:=module()
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
            build::static,
            bounds:=[Bound([-infinity,infinity],[false,false])];
    local   
            ModulePrint::static,
            ModuleApply::static;

    ModuleApply:=proc(cons::set({`=`,`<`,`<=`,`<>`}))
        local this,c;
        if numelems(indets(cons,name))<>1 
        or ormap(x->numelems(indets(cons,name))<>1,cons) then
            error "每个不等式（等式）都只能使用同一个变量";
        end if;
        this:=Object(Internal);
        for c in cons do
            this:=this and build(c);
        end do;
        return this;
    end proc:

    build:=proc(_con::{`=`,`<`,`<=`,`<>`})
        local c,obj,v;
        obj:=Object(Internal);
        c:=RealDomain:-solve({_con});
        if c={} then
            error "约束条件无解,%1",_con;
        end if;
        c:=c[];
        if type(c,`=`) then
            v:=rhs(c);
            obj:-bounds:=[Bound([v,v],[true,true])];
        elif type(c,{`<`,`<=`}) then
            if type(rhs(c),extended_numeric) then
                v:=rhs(c);
                obj:-bounds:=[Bound([-infinity,v],[false,type(c,`<=`)])];
            else
                v:=lhs(c);
                obj:-bounds:=[Bound([v,infinity],[type(c,`<=`),false])];
            end if;
        else
            v:=rhs(c);
            obj:-bounds:=[  Bound([-infinity,v],[false,false]),
                            Bound([v,infinity], [false,false]) ];
        end if;
        return obj;
    end proc:

    `and`:=proc(x::Internal,y::Internal)
        option overload;
        local z,bs;
        z:=Object(Internal);
        bs:=Matrix(numelems(x:-bounds),numelems(y:-bounds),
                    (i,j)->x:-bounds[i] &and y:-bounds[j]);
        bs:=convert(bs,list);
        bs:=select(Bound:-notNull,bs);
        z:-bounds:=bs;
        return z;
    end proc:

    `or`:=proc(x::Internal,y::Internal)
        option overload;
        local z,bs1,bs2,bs3,i,n,b;
        bs1:=x:-bounds;
        bs2:=y:-bounds;
        n:=numelems(bs2);
        bs3:=Array(1..n,i->0);
        for i from 1 to n do
            bs3(i),bs1:=boundsOr(bs1,bs2[i]);
            if bs1=[] then
                break;
            end if;
        end do;
        b:=bs3[1];
        for i from 2 to n do
            b:=b &or bs3[i];
        end do;
        # TODO: 剩余区间求并集，区间满足从大到小排列
    end proc:

    # 区间的交集和并集，快速算法是否可以用C实现？

    boundsOr:=proc(_bs::list(Bound),b::Bound)
        local bs,rs,r;
        bs,rs:=selectremove(x->isIntersected(x,b),_bs);
        r:=(bs[1] &or b) &or (bs[-1] &or b);
        return r,rs;
    end proc:

    ModulePrint:=proc(x::Internal)
        local i,n,s,sp:=" ∪ ",res;
        s:=Bound:-bound2str~(x:-bounds);
        n:=numelems(s);
        for i from 1 to n do
            if i=1 then
                res:=s[i];
            else
                res:=cat(res,sp,s[i]);
            end if;
        end do;
        return res;
    end proc:
    
end module:

$endif