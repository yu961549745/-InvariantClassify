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

	# ��ʱû���ظ�����Ԫ�Ĵ���
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
			# �������ƫ΢�ַ�����
			# ������з�����Ϊ�գ���ֹͣ���
			if evalb(sol:-oeq={}) then
				return;
			end if;
			nDelta:=getInvariants(sol:-oeq);
			# ���ʧ��
			if evalb(indets(nDelta,name) intersect {seq(a[i],i=1..sol:-nvars)} = {}) then
				# ���ʧ�ܲ���ӽ�
				# �����ǲ�����ⲻ���������
				return;
			end if;
			spos:=numelems(sol:-Delta)+1;
			sol:-Delta:=[sol:-Delta[],nDelta[]]:
			sol:-orders:=findInvariantsOrder~(sol:-Delta):
			# ��������ⲻ����������
			for pos from spos to numelems(sol:-Delta) do
				buildInvariantsEquations(sol,pos);
			end do;
			# �����µĲ�����
			genInvariants(sol);
		elif evalb(sol:-stateCode=2) then
			# ��ⲻ����������
			solveInvariantsEquations(sol);
		elif evalb(sol:-stateCode=3) then
			# ȡ����Ԫ
			fetchRep(sol);
		elif evalb(sol:-stateCode=4) then
			# ���任����
			solveTransformEquation(sol);
		end if;
		return;
	end proc:

	# �����������ķ�����
	buildInvariantsEquations:=proc(_sol::InvSol,pos::posint)
		global sols,cid;
		local sol,rs,i,n,x,xpos,eqs;
		n:=numelems(_sol:-Delta);
		# ����ż����
		# ���������Ƿ���
		# �������Ĵη����ǲ�������ֱ�ӿ�����
		# �������ڲ����������Ǳ��Ѿ��������ֻ������
		if type(numer(_sol:-orders[pos]),even) then
			xpos:=[1,-1,0];
		else
			xpos:=[1,0];
		end if;
		# ���ɷ����Ҷ�
		cid:=0;
		rs:=Array(1..n,x->
		if evalb(x>pos) then
			getCname()
		else
			0
		end if);
		# ����������
		for x in xpos do
			# ����Delta[pos]=0��������һ�����̽������
			# �����ȫ�㷽��
			if evalb(x=0) then
				# ������ÿ��ȫ�㷽�̶�����������˼
				# ����ֱ��next�ͺ���
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

	# �����µĴ���Ԫ
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

	# �����µĲ���������
	# ��ôд�ᵼ�ºͷ����ɱ����йص�ƫ�������0
	subsOeq:=proc(_sol::InvSol,isol)
		local oeq,sol,v,vv,vars,Delta;
		printf("--------------------------------------------------------------\n");
		printf("����µĲ�����\n");
		print(_sol:-oieq);
		printf("ȡ��\n");
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

	# ��ⲻ����������
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

	# �Բ�����ȫΪ0�ķ��̽������
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
				printf("���ȫ�㷽��\n");
				print(getDisplayIeq(nnsol));
				printf("ȡ��\n");
				print(nnsol:-isol);
				printf("����Լ������\n");
				print(nnsol:-icon);
				printf("ȡ�ؽ�\n");
				print(nnsol:-rvec);
				printf("ȡ����Ԫ\n");
				print(nnsol:-rep);
				resolve(nnsol);
			end do;
		end do;
	end proc:

	# ȡ����Ԫ
	fetchRep:=proc(_sol::InvSol)
		local n,_ax;
		printf("--------------------------------------------------------------\n");
		printf("���ڲ���������\n");
		print(getDisplayIeq(_sol));
		printf("ȡ��\n");
		print(_sol:-isol);
		printf("����Լ������\n");
		print(_sol:-icon);
		n:=_sol:-nvars;
		_ax:=fetchSimpleSolution(_sol);
		if evalb(_ax=NULL) then# ȡ�ؽ�ʧ��
			sols:=sols union {_sol};
			return;
		end if;
		setRep(_sol,_ax);
		if evalb(_sol:-rep=0) then
			printf("����Ԫȡ0\n");
			return;
		end if;
		_ax:=Matrix(_ax);
		_sol:-stateCode:=4;
		printf("ȡ�ؽ�\n");
		print(convert(_ax,list));
		printf("ȡ����Ԫ\n");
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
			# �޽�
			printf("�任�������ʧ��\n");
			sols:=sols union {_sol};
		else
			# �н�
			printf("�任�����н�\n");
			_sol:-stateCode:=5;
			sols:=sols union {_sol};
			printTeq(_sol,1);
			printTeq(_sol,2);
		end if;
		return;
	end proc:

	printTeq:=proc(sol,pos)
		if evalb(sol:-tsol[pos]=[]) then
			printf("�任���� %d �޽�\n",pos);
		else
			printf("�任���� %d �н�\n",pos);
			print(sol:-tsol[pos]);
			printf("��������\n");
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
			# ���ʧ�ܣ����Զ�����ⷨ����
			# �״����
			eqs:=convert~([RealDomain:-solve(teq)],radical);
			# �������
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
			# ���ɹ���ֱ�Ӽ���Լ��
			tcon:=map(x->clearConditions(findSolutionDomain(x)),tsol);
		end if;
		return teq,tsol,tcon;
	end proc:

	eqOfEpsilon:=proc(eq)
		return ormap(x->type(x,specindex(epsilon)),indets(eq,name));
	end proc:


	# ɾ����a�޹ص�Լ��
	clearConditions:=proc(con)
		return select(x->ormap(type,indets(x,name),specindex(a)),con);
	end proc:

	printSol:=proc(s::InvSol)
		printf("---------------------------------------------------------\n");
		if 	evalb(s:-stateCode=1) then
			printf("�µĲ��������ʧ�ܣ�״̬����1\n");
			print(s:-oieq);
			printf("ȡ��\n");
			print(s:-oisol);
			printf("���ʧ�ܵ�ƫ΢�ַ���Ϊ\n");
			print(s:-oeq);
		elif	evalb(s:-stateCode=2) then
			printf("�������������ʧ�ܣ�״̬����2\n");
			print(getDisplayIeq(s));
		elif	evalb(s:-stateCode=3) then
			printf("ȡ����Ԫʧ�ܣ�״̬����3\n");
			print(getDisplayIeq(s));
			printf("ȡ��\n");
			printf(s:-isol);
		elif	evalb(s:-stateCode=4) then
			printf("�任�������ʧ�ܣ�״̬����4\n");
			print(getDisplayIeq(s));
			printf("ȡ��\n");
			print(s:-isol);
			printf("����Լ��\n");
			print(s:-icon);
			printf("ȡ����Ԫ\n");
			print(s:-rep);
			printf("���ʧ�ܵ������任����Ϊ\n");
			print~(s:-teq);
		elif	evalb(s:-stateCode=5) then
			printf("�任�������ɹ���״̬����5\n");
			print(getDisplayIeq(s));
			printf("ȡ��\n");
			print(s:-isol);
			printf("����Լ��\n");
			print(s:-icon);
			printf("ȡ����Ԫ\n");
			print(s:-rep);
			printf("�任�����н�\n");
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