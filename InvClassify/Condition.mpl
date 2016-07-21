# ���ĳ�������
Condition:=module()
	option	package;
	export	findSolutionDomain;
	local	findDomain,
			findDomainCondtions,
			tassign,
			classifySolve;

	(*
	 * �� ��� ������
	 * ���ص�����������˵�����Լ��
	 * �����˶����Լ��
	 * �ں���ʹ���и��ݵ�����Լ��ȡ�ؽ⣬����֤�Ƿ���������Լ��
	 * ���������˹�ȡ�ؽ�
	*)
	findSolutionDomain:=proc(s)
		local con;
		con:=`union`(findDomain~(rhs~({s[]}))[]);
		return remove(x->type(x,`=`) and evalb(lhs(x)=rhs(x)),classifySolve(con)) 
		 union select(x->type(rhs(x),numeric),{s[]});
	end proc:

	(*
	 * �����ʽ�Ķ�����
	 * ֻ���� + * ^ ln
	*)
	findDomain:=proc(ee)
		local S,r;
		S:={};
		findDomainCondtions(ee,S);
		return S;
	end proc:

	(*
	 * �����ʽ�Ķ�����Լ������
	 * ֻ���� + * ^ ln
	*)
	findDomainCondtions:=proc(e,S::evaln(set))
		local _e;
		if type(e,`^`) then
			if evalb(op(2,e)<0) then
				if type(op(2,e),'fraction') and type(op(2,op(2,e)),'even') then
					S:=eval(S) union {op(1,e)>0};
				else
					S:=eval(S) union {op(1,e)<>0};
				end if;
			else
				if type(op(2,e),'fraction') and type(op(2,op(2,e)),'even') then
					S:=eval(S) union {op(1,e)>=0};
				end if;
			end if;
		elif type(e,`+`) or type(e,`*`) then
			for _e in e do
				findDomainCondtions(_e,S);
			end do;
		elif evalb(op(0,e)='ln') then
			S:=eval(S) union {op(e)>0};
		end if;
	end proc:

	tassign:=proc(t::table,k,v)
		if assigned(t[k]) then
			t[k]:=t[k] union {v};
		else
			t[k]:={v};
		end if;
		return;
	end proc:

	# ����ʽԼ���������
	# �ϲ�������Լ��
	# ���������Լ��
	classifySolve:=proc(con::set)
		local t,sd,ns,c,ind,x;
		t:=table();
		ns,sd:=selectremove(x->evalb(numelems(indets(x,name))=1),con);
		for c in ns do
			tassign(t,indets(c,name)[],c);
		end do;
		ind:=[indices(t,nolist)];
		for x in ind do
			t[x]:=RealDomain:-solve(t[x],{x});
		end do;
		ns:=`union`(entries(t,nolist));
		return sd union ns;
	end proc:
end module: