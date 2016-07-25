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
		csols:=[],# 合并的解
		ccons:=[],# 合并的条件
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
	# 重新取代表元
	# 会自动设置相关变量的值
	export setRep::static:=proc(s::InvSol,rvec::list)
		local v;
		s:-stateCode:=4;
		s:-rvec:=Matrix(rvec);
		s:-rep:=add(rvec[i]*v[i],i=1..numelems(rvec));
		return;
	end proc:
	# 重新对不变量方程取解
	export setIsol::static:=proc(s::InvSol,isol)
		s:-stateCode:=3;
		s:-isol:=isol;
		s:-icon:=findSolutionDomain(isol);
		return;
	end proc:
	# 输出解
	export printSol::static:=proc(s::InvSol)
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
	# 输出变换方程和解
	export printTeq::static:=proc(sol,pos)
		if evalb(sol:-tsol[pos]=[]) then
			printf("变换方程 %d 无解\n",pos);
		else
			printf("变换方程 %d 有解\n",pos);
			print(sol:-tsol[pos]);
			printf("具有条件\n");
			print(sol:-tcon[pos]);
		end if;
	end proc:
end module:
