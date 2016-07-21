# ȡ�ؽ�
Fetch:=module()
	option package;
	export	fetchSimpleSolution;
	local	fetchIeq;

	(*
	 * ȡ�ؽ�
	 * ���ɱ���ȡ0
	 * ���ݵ�����Լ��ȡ���ڽ�����
	 * ��֤�Ƿ���������Լ��
	 * ���㷵���ؽ⣬���򷵻�NULL
	*)
	fetchSimpleSolution:=proc(_sol::InvSol,{nonzero::boolean:=false,addcon:={}})
		local f,C,sc,vc,t,r,rf,_rf,i,n,sols,res,sol,con;
		sol:=_sol:-isol;
		con:=_sol:-icon union addcon;
		f:=select(x->evalb(lhs(x)=rhs(x)),sol);
		f:=indets(f,name) minus indets(con,name);
		C,t:=selectremove(x->type(x,`=`) and type(rhs(x),numeric),con);
		sc,vc:=selectremove(x->evalb(numelems(indets(x,name))=1),t);

		r:=fetchIeq~(sc) union C;
		rf:={seq(x=0,x in f)};
		if andmap(evalb,subs(r[],rf[],vc)) then
			res:=eval(subs(r[],rf[],rhs~(sol)));
		else
			res:=NULL;
		end if;
		if nonzero then
			if andmap(type,res,0) then
				sols:={};
				n:=numelems(rf);
				for i from 1 to n do
					_rf:=subsop([i,2]=1,rf);
					if andmap(evalb,subs(r[],_rf[],vc)) then
						sols:=sols union {eval(subs(r[],_rf[],rhs~(sol)))};
					end if;
				end do:
				res:=sols;
			else
				res:={res};
			end if;
		end if;
		return res;
	end proc:

	# ���� <> < <= ��Լ������ȡ�ؽ�
	# ȡ�������������ڽ�����
	fetchIeq:=proc(x)
		local r;
		if type(x,`<>`) then
			r:=lhs(x)=floor(rhs(x))+1;
		elif type(lhs(x),numeric) then
			if type(x,`<`) then
				r:=rhs(x)=floor(lhs(x))+1;
			else
				r:=rhs(x)=ceil(lhs(x));
			end if;
		else
			if type(x,`<`) then
				r:=lhs(x)=ceil(rhs(x))-1;
			else
				r:=lhs(x)=floor(rhs(x));
			end if;
		end if;
	end proc:

end module: