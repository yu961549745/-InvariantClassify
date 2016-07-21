(*
 * 保存不变量分类状态的对象
 * 
 * 状态分为：
 * 	1 线性偏微分方程组求解失败
 * 	2 不变量方程组求解失败
 * 	3 取特解失败
 * 	4 变换方程求解失败
 * 	5 变换方程求解成功，特解可能是代表元，是否是代表元留给人工判断
 * 	
 * 一个不变量方程可能有多个解
 * 一个解对应一个特解，对应一个代表元
 * 一个不变量方程可能有多个代表元
 * 一个特解只对应一个代表元
 * 但是这个代表元的条件比较飘渺
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
	# 带参数的初始化太麻烦了，ModuleApply和ModuleCopy不写了
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
