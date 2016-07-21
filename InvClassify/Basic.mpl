# ��������
#	�����ӱ�
#	����任����
#	��������ƫ΢�ַ���
#	����ƫ΢�ַ����󲻱���
#	���ո��Ӷ���������
Basic:=module()
	option package;
	export	d,
			setSymbols,
			getSymbols,
			getTransformMatrixAndPDE,
			getInvariants,
			sortByComplexity;
	local `&*`,ModuleLoad,getKd,getPmVec,ans2v,
		  default_syms:={x,y,z,t,u,v,w},syms:=default_syms,
		  getPDE,
		  simplifyInvariants,
		  invOrd,
		  simpleSimplify,
		  spAdd,spMul;
	uses `YJT/Pa`=`\x26\x50\x61\x72\x74\x69\x61\x6C\x44\x3B`;

	ModuleLoad:=proc()
		# ���ذ�ʱ�ı�΢�����ӵ���ʾ��ʽ
		PDETools:-declare('quiet'):
	end proc;
	ModuleLoad();
    

	(*
	 * �޸�΢�����ӵķ��ż���
	*)
	setSymbols:=proc(s::set(name):=default_syms)
		description "���ú����ı���������";
		syms:=s;
	end proc;

	(*
	 * ��ȡ����������
	*)
	getSymbols:=proc()
		description "��ȡ����������";
		syms;
	end proc;

	(*
	 * �Զ���΢�����Ӳ��������õ�����f��
	*)
	d:=proc()
		description "��������΢�����ӱ��ʽ";
		if not {_passed} subset syms then
			error sprintf("only can use symbols in %a ,"
			"use setSymbols command to use other symbols",syms);
		end if;
		diff(`YJT/Pa`(syms[]),_passed);
	end proc;

	# �Զ��彻���Ӽ����
	`&*`:=proc(a,b)
		description "������������΢�����ӵĽ�����";
		expand(eval(subs(`YJT/Pa`(syms[])=b,a)-subs(`YJT/Pa`(syms[])=a,b)));
	end proc:
	
	(*
	 * �����ʽ�ֽ�Ϊ���������ȡϵ��
	 * ���룺
	 *	  f ���ʽ
	 * �����
	 *	 T ��������->ϵ�� ��ӳ���
	*)
	getKd:=proc(f)
		local T:=table(),kd;
		
		(* 
		 * �����ʽ�ֽ�Ϊ�����Ի�����ȡϵ���ĵݹ��Ӻ���
		 * ���룺
		 *	 f ���ʽ
		 *	 T �������ı�
		 * �����
		 *	 T T�ᱻ�޸�
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
	 * ��ȡ���ʽ���ڸ������������ϵ������
	 * ���룺
	 *	 f	���ʽ
	 *	 s	�������
	 * �����
	 *	 v	ϵ������
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
	 * �����ʽ���ڻ������Ա��
	 * ���룺
	 *	 f	���ʽ
	 *	 A	�����ڷ��������ϵ������
	 *	 stbs	�������
	 *	 sbs	���ķ��ű�ʾ
	 * �����
	 *	 r	���ʽ���ڻ������Ա�������ʧ�ܷ���ԭ���ʽ
	*)
	ans2v:=proc(f,A,stbs)
		local r;
		try
			r:=LinearAlgebra[LinearSolve](A,getPmVec(f,stbs));
		catch:
			error "��������Ԫ���ܹ���һ���";
		end try;
	end proc:
	

	(*
	* �������н��
	* ���룺һ������Ԫ
	* �����
	* 	AD	����任���������
	* 	ADA	A[1]*A[2]*...*A[n]
	* 	dts	����������
	*)
	getTransformMatrixAndPDE:=proc(vv::list)
		local tbs,stbs,vvv,M,n,sbs,i,j,A,tmpv,MK,AD,ADA,ADT,BA,pPhi,eq,AList,dts,eqs;
		
		vvv:=expand(vv):
		n:=numelems(vvv):
		sbs:=Vector[row](1..n,i->cat(''v'',``[i])):# ����Ԫ�ı�ʾ����
		printf("Input:");
		print(seq(sbs[i]=vv[i],i=1..n));
		
		# ���㽻���Ӿ�������õ����ǹ���f�Ľ������Ҫ��һ���û���ʾ
		M:=Matrix(1..n, 1..n, (i, j)->vvv[i] &* vvv[j]):
		MK:=Matrix(1..n,1..n);
		
		# ��ԭ�����ӱ��û����
		tbs:=getKd~(vvv):# ���������ϵ��ӳ���
		stbs:={map(indices,tbs,'nolist')[]}:# �������
		# ����Ԫ���ڷ��������ϵ������
		A:=Matrix(1..numelems(stbs),1..numelems(tbs),
		(i,j)->`if`(assigned(tbs[j][stbs[i]]),tbs[j][stbs[i]],0)):
		# ����ÿ�������ӹ�������Ԫ��ϵ��
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
		printf("Commutator table:");		
		print(M);

		
		# �������
		AD:=Array(1..n);
		ADA:=LinearAlgebra[IdentityMatrix](n);
		ADT:=Matrix(1..n,1..n);
		printf("Adjoint transformation matrixes :\n");
		for i from 1 to n do
			AD[i]:=LinearAlgebra[MatrixExponential](Matrix(convert(MK[i],list)),-epsilon[i]);
			ADA:=ADA.AD[i];
			ADT(i,1..n):=subs~(epsilon[i]=epsilon,(AD[i].sbs^%T)^%T);
			printf("Adjoint transformation matrix of %a",sbs[i]);
			print(AD[i]);
		end do;
		printf("General adjoint transformation matrix");
		print(ADA);

		printf("Adjoint representation table:");
		print(ADT);

		# ���㲻����
		BA:=Matrix(1..n,1..n,(i,j)->b[i]*a[j]);
		pPhi:=add(BA*~M);
		eqs:=getPDE(pPhi,sbs);
		return AD,ADA,eqs;
	end proc:

	(*
	 * ���㲻����
	*)
	getInvariants:=proc(eqs)
		local res;
		printf("ƫ΢�ַ���\n");
		print~(eqs);
		res:=pdsolve(eqs);
		res:=res[];
		res:=[op(op(2,res))];
		res:=sortByComplexity(res);# ���ո��Ӷ��������
		printf("��õĲ�����\n");
		map(x->print('Delta'[x]=res[x]),[seq(i,i=1..numelems(res))]);
		res:=simplifyInvariants(res);# ����������
		res:=simpleSimplify~(res);
		res:=sortByComplexity(res);# ���ո��Ӷ��������
		printf("�����Ĳ�����\n");
		map(x->print('Delta'[x]=res[x]),[seq(i,i=1..numelems(res))]);
		return res;
	end proc;

	(*
	 * ���ɲ�������ƫ΢�ַ�����
	 * ���룺
	 * 	p		[w,v],w=sum(b[j]*v[j]),v=sum(a[i]*v[i])
	 * 	sbs		����Ԫ���ż�
	 * �����
	 * 	ƫ΢�ַ�����
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
	 * ���򲻱���
	 * ����һ���������ķ��Ӻͷ�ĸ���ֱ����ó˷��ͼӷ��Ĺ�����л���
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

	# ����������Ľ����Ƿ�����
	# �͵����������Ľ���
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
	 * ��������
	 * 	D[i]=f(D[j1],D[j2],...,D[jn])+g(a[1],...,a[m]), j1,j2,...,jn!=i
	 * �򻯼�Ϊ
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
	 * ��������
	 * 	D[i]=f(D[j1],D[j2],...,D[jn])*g(a[1],...,a[m]), j1,j2,...,jn!=i
	 * �򻯼�Ϊ
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
	 * �������ļ򵥻���
	 * ��ȥ��ĸ�еı���
	*)
	simpleSimplify:=proc(ee)
		local n,d;
		n:=numer(ee);
		d:=denom(ee);
		d:=factor(d);
		if type(d,`*`) then
			# �����д���������ط���forѭ����low�ˡ�
			d:=remove(type,d,'numeric');
		elif type(d,'numeric') then
			d:=1;
		end if;
		return simplify(n/d);
	end proc;

	(*
	 * ���ո��Ӷ�����
	*)
	sortByComplexity:=proc(s::list)
		return ListTools[Reverse](SolveTools[SortByComplexity](s));
	end proc:
	
end module: