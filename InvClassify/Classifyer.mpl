Classifyer:=module()
	option package;
	local	cid:=0,
			ieqCode:=0,
			getIeqCode,
			getCname,
			buildInvariantsEquations,
			genInvariants,
			subsOeq,
			solveInvariantsEquations,
			fetchRep,
			solveTransformEquation,
			clearConditions,
			eqOfEpsilon,
			sols,
			solveAllZero;
	export	classify,
			resolve,
			getSols,
			printSol,
			printSols,
			solveTeq,
			printTeq;

	classify:=proc(A,As,eqs)
		local sol;
		sols:={};
		sol:=Object(InvSol):
		sol:-stateCode:=1:
		sol:-oeq:=eqs:
		sol:-As:=As:
		sol:-A:=A:
		sol:-nvars:=LinearAlgebra[RowDimension](A):
		sol:-vars:=[seq(a[i],i=1..sol:-nvars)]:
		resolve(sol);
		return;
	end proc:

	# 暂时没做重复代表元的处理
	getSols:=proc()
		return sort([sols[]],'key'=(x->x:-ieqCode));
	end proc:

	getCname:=proc()
		cid:=cid+1;
		return c[cid];
	end proc:

	getIeqCode:=proc()
		ieqCode:=ieqCode+1;
		return ieqCode;
	end proc:

	resolve:=proc(sol::InvSol)
		local spos,pos,nDelta;
		
		if evalb(sol:-stateCode=1) then
			# 尝试求解偏微分方程组
			# 如果所有方程组为空，则停止求解
			if evalb(sol:-oeq={}) then
				return;
			end if;
			nDelta:=getInvariants(sol:-oeq);
			# 求解失败
			if evalb(indets(nDelta,name) intersect {seq(a[i],i=1..sol:-nvars)} = {}) then
				# 求解失败不添加解
				# 不考虑不能求解不变量的情况
				return;
			end if;
			spos:=numelems(sol:-Delta)+1;
			sol:-Delta:=[sol:-Delta[],nDelta[]]:
			sol:-orders:=findInvariantsOrder~(sol:-Delta):
			# 建立和求解不变量方程组
			for pos from spos to numelems(sol:-Delta) do
				buildInvariantsEquations(sol,pos);
			end do;
			# 生成新的不变量
			genInvariants(sol);
		elif evalb(sol:-stateCode=2) then
			# 求解不变量方程组
			solveInvariantsEquations(sol);
		elif evalb(sol:-stateCode=3) then
			# 取代表元
			fetchRep(sol);
		elif evalb(sol:-stateCode=4) then
			# 求解变换方程
			solveTransformEquation(sol);
		end if;
		return;
	end proc:

	# 建立不变量的方程组
	buildInvariantsEquations:=proc(_sol::InvSol,pos::posint)
		global sols,cid;
		local sol,rs,i,n,x,xpos,eqs;
		n:=numelems(_sol:-Delta);
		# 分奇偶讨论
		# 阶数可能是分数
		# 不变量的次方还是不变量，直接看分子
		# 不过现在不变量化简那边已经加了这种化简规则
		if type(numer(_sol:-orders[pos]),even) then
			xpos:=[1,-1,0];
		else
			xpos:=[1,0];
		end if;
		# 生成方程右端
		cid:=0;
		rs:=Array(1..n,x->
		if evalb(x>pos) then
			getCname()
		else
			0
		end if);
		# 逐个方程求解
		for x in xpos do
			# 对于Delta[pos]=0，构建下一个方程进行求解
			# 不求解全零方程
			if evalb(x=0) then
				# 这里是每个全零方程都进行求解的意思
				# 否则直接next就好了
				if evalb(pos<>n) then
					next;
				else
					solveAllZero(_sol);
					return;
				end if;

				# next;
			end if;
			rs[pos]:=x;
			eqs:=[seq(_sol:-Delta[i]=rs[i],i=1..n)];
			sol:=Object(_sol);
			sol:-ieqCode:=getIeqCode();
			sol:-ieq:=eqs;
			sol:-stateCode:=2;
			resolve(sol);
		end do;
		return;
	end proc:

	# 生成新的代表元
	genInvariants:=proc(_sol::InvSol)
		local isols,isol,oeq,sol,oieq;
		oieq:={seq(Delta[i]=0,i=1..numelems(_sol:-Delta))};
		sol:=Object(_sol);
		sol:-oieq:=oieq;
		sol:-ieqCode:=getIeqCode();
		isols:=RealDomain[solve](sol:-Delta,[seq(a[i],i=1..sol:-nvars)]);
		for isol in isols do
			subsOeq(sol,isol);
		end do;
	end proc:

	# 生成新的不变量方程
	# 这么写会导致和非自由变量有关的偏导都变成0
	subsOeq:=proc(_sol::InvSol,isol)
		local oeq,sol,v,vv,vars,Delta;
		printf("--------------------------------------------------------------\n");
		printf("求解新的不变量\n");
		print(_sol:-oieq);
		printf("取解\n");
		print(isol);
		oeq:=_sol:-oeq;
		vars:=_sol:-vars;
		v,vv:=selectremove(x->evalb(lhs(x)<>rhs(x)),isol);
		vv:=lhs~(vv);
		oeq:=PDETools:-dsubs(phi(vars[])=phi(vv[]),oeq);
		oeq:=eval(subs(v[],oeq)) minus {0};
		sol:=Object(_sol);
		sol:-oisol:=isol;
		sol:-stateCode:=1;
		sol:-oeq:=oeq;
		sol:-vars:=vv;
		resolve(sol);
	end proc:

	# 求解不变量方程组
	solveInvariantsEquations:=proc(_sol::InvSol)
		local isols,icons,n,vars,sol,i;
		n:=_sol:-nvars;
		vars:=[seq(a[i],i=1..n)];
		isols:=RealDomain[solve](_sol:-ieq,vars);
		isols:=convert~(isols,radical);
		icons:=findSolutionDomain~(isols);
		n:=numelems(isols);
		for i from 1 to n do
			sol:=Object(_sol);
			sol:-stateCode:=3;
			sol:-isol:=isols[i];
			sol:-icon:=icons[i];
			resolve(sol);
		end do;
		return;
	end proc:

	# 对不变量全为0的方程进行求解
	solveAllZero:=proc(_sol)
		local sol,var,isols,icons,i,n,reps,rep,nsol,nnsol;
		sol:=Object(_sol);
		sol:-ieq:=[seq(x=0,x in sol:-Delta)];
		sol:-ieqCode:=getIeqCode();
		var:=[seq(a[i],i=1..sol:-nvars)];
		isols:=RealDomain:-solve(sol:-Delta,var);
		icons:=findSolutionDomain~(isols);
		n:=numelems(isols);
		for i from 1 to n do
			nsol:=Object(sol);
			nsol:-isol:=isols[i];
			nsol:-icon:=icons[i];
			reps:=fetchSimpleSolution(nsol,nonzero);
			for rep in reps do
				nnsol:=Object(nsol);
				nnsol:-stateCode:=4;
				setRep(nnsol,rep);
				printf("--------------------------------------------------------------\n");
				printf("求解全零方程\n");
				print(getDisplayIeq(nnsol));
				printf("取解\n");
				print(nnsol:-isol);
				printf("具有约束条件\n");
				print(nnsol:-icon);
				printf("取特解\n");
				print(nnsol:-rvec);
				printf("取代表元\n");
				print(nnsol:-rep);
				resolve(nnsol);
			end do;
		end do;
	end proc:

	# 取代表元
	fetchRep:=proc(_sol::InvSol)
		local n,_ax;
		printf("--------------------------------------------------------------\n");
		printf("对于不变量方程\n");
		print(getDisplayIeq(_sol));
		printf("取解\n");
		print(_sol:-isol);
		printf("具有约束条件\n");
		print(_sol:-icon);
		n:=_sol:-nvars;
		_ax:=fetchSimpleSolution(_sol);
		if evalb(_ax=NULL) then# 取特解失败
			sols:=sols union {_sol};
			return;
		end if;
		setRep(_sol,_ax);
		if evalb(_sol:-rep=0) then
			printf("代表元取0\n");
			return;
		end if;
		_ax:=Matrix(_ax);
		_sol:-stateCode:=4;
		printf("取特解\n");
		print(convert(_ax,list));
		printf("取代表元\n");
		print(_sol:-rep);
		resolve(_sol);
	end proc:

	solveTransformEquation:=proc(_sol::InvSol)
		local ax,_ax,n,eq,sol,con;
		n:=_sol:-nvars;
		ax:=Matrix([seq(a[i],i=1..n)]);
		_ax:=_sol:-rvec;
		# a_=a.A
		_sol:-teq[1],_sol:-tsol[1],_sol:-tcon[1]:=solveTeq(_ax,ax,_sol);
		# a=a_.A
		_sol:-teq[2],_sol:-tsol[2],_sol:-tcon[2]:=solveTeq(ax,_ax,_sol);
		if andmap(x->evalb(x=[]),_sol:-tsol) then
			# 无解
			printf("变换方程求解失败\n");
			sols:=sols union {_sol};
		else
			# 有解
			printf("变换方程有解\n");
			_sol:-stateCode:=5;
			sols:=sols union {_sol};
			printTeq(_sol,1);
			printTeq(_sol,2);
		end if;
		return;
	end proc:

	printTeq:=proc(sol,pos)
		if evalb(sol:-tsol[pos]=[]) then
			printf("变换方程 %d 无解\n",pos);
		else
			printf("变换方程 %d 有解\n",pos);
			print(sol:-tsol[pos]);
			printf("具有条件\n");
			print(sol:-tcon[pos]);
		end if;
	end proc:


	solveTeq:=proc(a,b,sol)
		local var,teq,tsol,tcon,scon,eqs,eq,_eq,_con,_sol;
		teq:=convert((a-b.sol:-A),list);
		teq:=subs(sol:-isol[],teq);
		var:=[seq(epsilon[i],i=1..sol:-nvars)];
		tsol:=convert~(RealDomain:-solve(teq,var),radical);
		if evalb(tsol=[]) then
			# 求解失败，尝试二次求解法方法
			# 首次求解
			eqs:=convert~([RealDomain:-solve(teq)],radical);
			# 二次求解
			tsol:=[];
			tcon:=[];
			for eq in eqs do
				_eq:=select(eqOfEpsilon,eq);
				_con:=remove(eqOfEpsilon,eq);
				_con:=remove(x->type(x,`=`) and evalb(lhs(x)=rhs(x)),_con);
				_sol:=convert~(RealDomain:-solve(_eq,var),radical);
				_con:=map(x->clearConditions(findSolutionDomain(x)) union _con,_sol);
				tsol:=[tsol[],_sol[]];
				tcon:=[tcon[],_con[]];
			end do;
		else
			# 求解成功，直接计算约束
			tcon:=map(x->clearConditions(findSolutionDomain(x)),tsol);
		end if;
		return teq,tsol,tcon;
	end proc:

	eqOfEpsilon:=proc(eq)
		return ormap(x->type(x,specindex(epsilon)),indets(eq,name));
	end proc:


	# 删除与a无关的约束
	clearConditions:=proc(con)
		return select(x->ormap(type,indets(x,name),specindex(a)),con);
	end proc:

	printSol:=proc(s::InvSol)
		printf("---------------------------------------------------------\n");
		if 	evalb(s:-stateCode=1) then
			printf("新的不变量求解失败，状态代码1\n");
			print(s:-oieq);
			printf("取解\n");
			print(s:-oisol);
			printf("求解失败的偏微分方程为\n");
			print(s:-oeq);
		elif	evalb(s:-stateCode=2) then
			printf("不变量方程求解失败，状态代码2\n");
			print(getDisplayIeq(s));
		elif	evalb(s:-stateCode=3) then
			printf("取代表元失败，状态代码3\n");
			print(getDisplayIeq(s));
			printf("取解\n");
			printf(s:-isol);
		elif	evalb(s:-stateCode=4) then
			printf("变换方程求解失败，状态代码4\n");
			print(getDisplayIeq(s));
			printf("取解\n");
			print(s:-isol);
			printf("具有约束\n");
			print(s:-icon);
			printf("取代表元\n");
			print(s:-rep);
			printf("求解失败的两个变换方程为\n");
			print~(s:-teq);
		elif	evalb(s:-stateCode=5) then
			printf("变换方程求解成功，状态代码5\n");
			print(getDisplayIeq(s));
			printf("取解\n");
			print(s:-isol);
			printf("具有约束\n");
			print(s:-icon);
			printf("取代表元\n");
			print(s:-rep);
			printf("变换方程有解\n");
			printTeq(s,1);
			printTeq(s,2);
		end if;
		printf("---------------------------------------------------------\n");
		return;
	end proc:

	printSols:=proc(sols::list(InvSol))
		local n,i;
		n:=numelems(sols);
		for i from 1 to n do
			printf("---------------------------------------------------------\n");
			printf("sols[%d]\n",i);
			printSol(sols[i]);
		end do;
		return sols;
	end proc:

end module: