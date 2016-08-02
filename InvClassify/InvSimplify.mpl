(*
	化简不变量
	对于一个不变量的分子和分母，分别尝试用乘法和加法的规则进行化简
	不改变不变量的顺序。
*)
simplifyInvariants:=proc(iinvs)
	local invs,tmp,i,j,n,vars,vset,vv,v1,v2;
	invs:=iinvs;
	n:=numelems(invs);
	vars:=[seq(_Delta[i],i=1..n)];
	vset:={vars[]};
	# 尝试将不变量进行整体代换并进行化简
	for i from 1 to n do
		tmp:=invs[i];
		for j from 1 to n do
			if evalb(i<>j) then
				try tmp:=algsubs(invs[j]=vars[j],tmp);
				catch:
				end try;
			end if;
		end do;
		invs[i]:=spAdd(spMul(numer(tmp),vset),vset)/spAdd(spMul(denom(tmp),vset),vset);
	end do;
	vv:=[seq(vars[i]=invs[i],i=1..n)];
	# 将不能化简掉的整体代回原表达式
	while true do
		(v1,v2):=selectremove(e->evalb(indets(rhs(e),'name') intersect vset <> {}),vv);
		if evalb(v1=[]) then
			break;
		end if;
		v1:=subs(v2[],v1);
		vv:=[v1[],v2[]];
	end do;
	vv:={vv[]};# 为了按照Delta排序
	vv:=rhs~([vv[]]);# 返回list才能保持顺序不变
	vv:=invOrd~(vv);
	vv:=simplify(vv);
	return simpleSimplify~(vv);
end proc;

# 如果不变量的阶数是分数的
# 就调整不变量的阶数
invOrd:=proc(v)
	local ord;
	ord:=findInvariantsOrder(v);
	if type(ord,fraction) then
		return v^denom(ord);
	else
		return v;
	end if;
end proc:

(*
	* 若不变量
	* 	D[i]=f(D[j1],D[j2],...,D[jn])+g(a[1],...,a[m]), j1,j2,...,jn!=i
	* 则化简为
	* 	D[i]=g(a[1],...,a[m])
*)
spAdd:=proc(ee,vars)
	local e,_e,s;
	e:=expand(ee);
	if not type(e,`+`) then
		return e;
	end if;
	s:=0;
	for _e in e do
		if not indets(_e,'name') subset vars then
			s:=s+_e;
		end if;
	end do;
	return s;
end proc;

(*
	* 若不变量
	* 	D[i]=f(D[j1],D[j2],...,D[jn])*g(a[1],...,a[m]), j1,j2,...,jn!=i
	* 则化简为
	* 	D[i]=g(a[1],...,a[m])
*)
spMul:=proc(ee,vars)
	local e,_e,p;
	e:=factor(ee);
	if not type(e,`*`) then
		return e;
	end if;
	p:=1;
	for _e in e do
		if not indets(_e,'name') subset vars then
			p:=p*_e;
		end if;
	end do;
	return p;
end proc;

(*
	* 不变量的简单化简
	* 消去分子分母中的倍数
*)
simpleSimplify:=proc(ee)
	local n,d;
	n:=rmK(numer(ee));
	d:=rmK(denom(ee));
	return simplify(expand(n/d));
end proc:

# 删除多项式的倍数
rmK:=proc(_e)
	local e,r;
	e:=expand(_e);
	if type(e,`+`) then
		r:=e/myGcd(map(x->select(type,x,numeric),[op(e)]));
	else
		r:=remove(type,e,numeric);
	end if;
	if evalb(r=NULL) then
		r:=1;
	end if;	
	return r;
end proc:

# 多个数的gcd
myGcd:=proc(ks)
	local k,i,n;
	k:=ks[1];
	n:=numelems(ks);
	for i from 2 to n do
		k:=gcd(k,ks[i]);
	end do;
	return k;
end proc: