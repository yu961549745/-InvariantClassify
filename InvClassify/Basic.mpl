(*
	* 修改微分算子的符号集合
*)
setSymbols:=proc(s::set(name):=default_syms)
	description "设置函数的变量名集合";
	if evalb( s intersect pnames <> {}) then
		error "变量不能包含%1",pnames;
	end if; 
	syms:=s;
end proc;

(*
	* 获取变量名集合
*)
getSymbols:=proc()
	description "获取变量名集合";
	syms;
end proc;

(*
	* 自定义微分算子操作，作用到函数f上
*)
d:=proc()
	description "用于生成微分算子表达式";
	if not {_passed} subset syms then
		error "表达式只能包含以下变量 %1, 可以使用 setSymbols 设置变量集合，但是不能包含 %2",syms,pnames;
	end if;
	return diff(Pa(syms[]),_passed);
end proc;

# 自定义交换子计算符
`&*`:=proc(a,b)
	description "计算两个生成微分算子的交换子";
	expand(eval(subs(Pa(syms[])=b,a)-subs(Pa(syms[])=a,b)));
end proc:

(*
	* 将表达式分解为非线性项并提取系数
	* 输入：
	*	  f 表达式
	* 输出：
	*	 T 非线性项->系数 的映射表
*)
getKd:=proc(f)
	local T:=table(),kd;
	
	(* 
		* 将表达式分解为非线性基并提取系数的递归子函数
		* 输入：
		*	 f 表达式
		*	 T 保存结果的表
		* 输出：
		*	 T T会被修改
	*)
	kd:=proc(f,T)
	local i,p,v,x;
	if type(f,`+`) then
		for i from 1 to nops(f) do
			thisproc(op(i,f),T);
		end do;
	elif type(f,`*`) then
		p:=1;
		v:=1;
		for i from 1 to nops(f) do
			x:=op(i,f);
			if type(x,'extended_numeric') then
				p:=p*x;
			else
				v:=v*x;
			end if;
		end do;
		T[v]:=p;
	else
		T[f]:=1;
	end if;
	return;
	end proc:
	
	kd(f,T);
	return eval(T);
end proc:

(*
	* 获取表达式关于给定非线性项集的系数向量
	* 输入：
	*	 f	表达式
	*	 s	非线性项集
	* 输出：
	*	 v	系数向量
*)
getPmVec:=proc(f,s)
	local n,v,i,tb;
	tb:=getKd(f);
	n:=numelems(s);
	v:=Vector(n);
	for i from 1 to n do
		if assigned(tb[s[i]]) then
			v[i]:=tb[s[i]];
		end if;
	end do;
	return eval(v);
end proc:

(*
	* 求解表达式关于基的线性表出
	* 输入：
	*	 f	表达式
	*	 A	基关于非线性项集的系数矩阵
	*	 stbs	非线性项集
	*	 sbs	基的符号表示
	* 输出：
	*	 r	表达式关于基的线性表出，求解失败返回原表达式
*)
ans2v:=proc(f,A,stbs)
	local r;
	try
		r:=LinearAlgebra[LinearSolve](A,getPmVec(f,stbs));
	catch:
		error "所给生成元不能构成一组基";
	end try;
end proc:


(*
* 计算所有结果
* 输入：一组生成元
* 输出：
* 	AD	伴随变换矩阵的数组
* 	ADA	A[1]*A[2]*...*A[n]
* 	dts	不变量数组
*)
getTransMatAndPDE:=proc(vv::list)
	local tbs,stbs,vvv,M,n,sbs,i,j,A,tmpv,MK,AD,ADA,ADT,BA,pPhi,eq,AList,dts,eqs;

	if not (indets(vv,name) subset syms) then
		error "表达式只能包含以下变量 %1, 可以使用 setSymbols 设置变量集合，但是不能包含 %2",syms,pnames;
	end if; 
	
	vvv:=expand(vv):
	n:=numelems(vvv):
	sbs:=Vector[row](1..n,i->v[i]):# 生成元的表示符号
	flogf[2]("Input:");
	flog[2](seq(sbs[i]=vv[i],i=1..n));
	
	# 计算交换子矩阵，这里得到的是关于f的结果，需要进一步用基表示
	M:=Matrix(1..n, 1..n, (i, j)->vvv[i] &* vvv[j]):
	MK:=Matrix(1..n,1..n);
	
	# 将原交换子表用基表出
	tbs:=getKd~(vvv):# 非线性项及其系数映射表
	stbs:={map(indices,tbs,'nolist')[]}:# 非线性项集
	# 生成元关于非线性项集的系数矩阵
	A:=Matrix(1..numelems(stbs),1..numelems(tbs),
	(i,j)->`if`(assigned(tbs[j][stbs[i]]),tbs[j][stbs[i]],0)):
	# 计算每个交换子关于生成元的系数
	for i from 1 to n do
		for j from 1 to n do
			if evalb(M(i,j)<>0) then
				if evalb(i<=j) then
					tmpv:=ans2v(M(i,j),A,stbs);
					M(i,j):=sbs.tmpv;
					MK(i,j):=convert(tmpv,list);
				else
					M(i,j):=-M(j,i);
					MK(i,j):=-MK(j,i);
				end if;
			else
				MK(i,j):=convert(Vector[row](1..n),list);
			end if;
		end do;
	end do;
	flogf[2]("Commutator table:");		
	flog[2](M);

	
	# 伴随矩阵
	AD:=Array(1..n);
	ADA:=LinearAlgebra[IdentityMatrix](n);
	ADT:=Matrix(1..n,1..n);
	flogf[2]("Adjoint transformation matrixes :\n");
	for i from 1 to n do
		AD[i]:=LinearAlgebra[MatrixExponential](Matrix(convert(MK[i],list)),-epsilon[i]);
		ADA:=ADA.AD[i];
		ADT(i,1..n):=subs~(epsilon[i]=epsilon,(AD[i].sbs^%T)^%T);
		flogf[2]("Adjoint transformation matrix of %a",sbs[i]);
		flog[2](AD[i]);
	end do;
	flogf[2]("General adjoint transformation matrix");
	flog[2](ADA);

	flogf[2]("Adjoint representation table:");
	flog[2](ADT);

	# 计算不变量
	BA:=Matrix(1..n,1..n,(i,j)->b[i]*a[j]);
	pPhi:=add(BA*~M);
	eqs:=getPDE(pPhi,sbs);
	return AD,ADA,eqs;
end proc:

(*
	* 计算不变量
*)
getInvariants:=proc(eqs)
	local res;
	flogf[1]("偏微分方程\n");
	flog[1]~(eqs);
	res:=pdsolve(eqs);
	res:=res[];
	res:=[op(op(2,res))];
	res:=sortByComplexity(res);# 按照复杂度升序输出
	flogf[1]("解得的不变量\n");
	map(x->flog[1]('Delta'[x]=res[x]),[seq(i,i=1..numelems(res))]);
	res:=simplifyInvariants(res);# 不变量化简
	res:=simpleSimplify~(res);
	res:=sortByComplexity(res);# 按照复杂度升序输出
	flogf[1]("化简后的不变量\n");
	map(x->flog[1]('Delta'[x]=res[x]),[seq(i,i=1..numelems(res))]);
	return res;
end proc;

(*
	* 生成不变量的偏微分方程组
	* 输入：
	* 	p		[w,v],w=sum(b[j]*v[j]),v=sum(a[i]*v[i])
	* 	sbs		生成元符号集
	* 输出：
	* 	偏微分方程组
*)
getPDE:=proc(p,sbs)
	local n:=numelems(sbs),syms:=[seq(a[i],i=1..n)],i,eq,eqs,
		bList:=[seq(b[i],i=1..n)];
	uses phi=phi(syms[]);
	eq:=add(seq(Phi[i]*diff(phi,syms[i]),i=1..n));
	for i from 1 to n do
		eq:=subs(Phi[i]=coeff(p,sbs[i]),eq);
	end do;
	eqs:={seq(coeff(eq,bList[i]),i=1..n)} minus {0};
end proc:

(*
	* 化简不变量
	* 对于一个不变量的分子和分母，分别尝试用乘法和加法的规则进行化简
*)
simplifyInvariants:=proc(iinvs)
	local invs,tmp,i,j,n,vars,vset,vv,v1,v2;
	invs:=iinvs;
	n:=numelems(invs);
	vars:=[seq(_Delta[i],i=1..n)];
	vset:={vars[]};
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
	while true do
		(v1,v2):=selectremove(e->evalb(indets(rhs(e),'name') intersect vset <> {}),vv);
		if evalb(v1=[]) then
			break;
		end if;
		v1:=subs(v2[],v1);
		vv:=[v1[],v2[]];
	end do;
	vv:={vv[]};
	vv:=rhs~(vv);
	vv:=invOrd~(vv);
	vv:=simplify([vv[]]);
	return vv;
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
	* 消去分母中的倍数
*)
simpleSimplify:=proc(ee)
	local n,d;
	n:=numer(ee);
	d:=denom(ee);
	d:=factor(d);
	if type(d,`*`) then
		# 巧妙的写法，其它地方的for循环都low了。
		d:=remove(type,d,'numeric');
	elif type(d,'numeric') then
		d:=1;
	end if;
	return simplify(n/d);
end proc;
