# ���㲻��������
InvOrder:=module()
	option package;
	export findInvariantsOrder;
	local findOrder,findItemOrder;

	(*
	 * ���㲻�����Ĵ���
	*)
	findInvariantsOrder:=proc(ee)
		if not type(denom(ee),'numeric') then
			return findOrder(numer(ee))-findOrder(denom(ee));
		else
			return findOrder(ee);
		end if;
	end proc:

	(*
	 * ������α��ʽ�ĵĴ�����������ĸ��
	*)
	findOrder:=proc(ee)
		local e;
		e:=expand(ee);
		if type(e,`+`) then
			e:=op(1,e);
		end if;
		e:=remove(type,e,'numeric');
		return findItemOrder(e);
	end proc:

	(*
	 * ����һ��Ĵ���
	*)
	findItemOrder:=proc(ee)
		local s,_e;
		s:=0;
		for _e in ee do
			if type(_e,`^`) then
				s:=s+op(2,_e);
			else
				s:=s+1;
			end if;
		end do;
	end proc:
end module: