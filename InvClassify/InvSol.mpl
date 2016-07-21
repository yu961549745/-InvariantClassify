(*
 * ���治��������״̬�Ķ���
 * 
 * ״̬��Ϊ��
 * 	1 ����ƫ΢�ַ��������ʧ��
 * 	2 ���������������ʧ��
 * 	3 ȡ�ؽ�ʧ��
 * 	4 �任�������ʧ��
 * 	5 �任�������ɹ����ؽ�����Ǵ���Ԫ���Ƿ��Ǵ���Ԫ�����˹��ж�
 * 	
 * һ�����������̿����ж����
 * һ�����Ӧһ���ؽ⣬��Ӧһ������Ԫ
 * һ�����������̿����ж������Ԫ
 * һ���ؽ�ֻ��Ӧһ������Ԫ
 * �����������Ԫ�������Ƚ�Ʈ��
*)
InvSol:=module()
	option object;
	export 
		stateCode::{1,2,3,4,5},
		oieq:={},
		oisol,
		oeq::set,
		Delta:=[],
		orders::list,
		ieqCode,
		ieq::list,
		isol,
		icon::set,
		teq:=[[],[]],
		tsol:=[[],[]],
		tcon:=[[],[]],
		rep,
		rvec,
		vars,
		nvars,
		As::static,
		A::static;
	# �������ĳ�ʼ��̫�鷳�ˣ�ModuleApply��ModuleCopy��д��
	export getDisplayIeq::static:=proc(self::InvSol)
		local Delta;
		return {seq(Delta[i]=rhs(self:-ieq[i]),i=1..numelems(self:-Delta))};
	end proc:
	export getDesc::static:=proc(s)
		if   evalb(s:-stateCode=1) then
			return s:-oeq;
		elif evalb(s:-stateCode=2) then
			return getDisplayIeq(s);
		elif evalb(s:-stateCode=3) then
			return s:-isol;
		elif evalb(s:-stateCode=4) then
			return s:-rep;
		elif evalb(s:-stateCode=5) then
			return s:-rep;
		end if;
	end proc:
	export ModulePrint::static:=proc(s)
		return getDesc(s);
	end proc:
	export setRep::static:=proc(s::InvSol,rvec::list)
		local v;
		s:-stateCode:=4;
		s:-rvec:=Matrix(rvec);
		s:-rep:=add(rvec[i]*v[i],i=1..numelems(rvec));
	end proc:
	export key::static:=proc(s)
		return expand([s:-stateCode,convert(s:-rvec,list)[]]);
	end proc:
end module:
