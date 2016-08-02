InvClassify:=module()
	option	package;
    $include "headers.mpl"

    $include "InvSol.mpl"
    $include "RepSol.mpl"

	$include "Basic.mpl"
	$include "Classifyer.mpl"
	$include "Combine.mpl"
	$include "Condition.mpl"
	$include "Fetch.mpl"
	$include "InvOrder.mpl"
	$include "Interaction.mpl"
	$include "InvSimplify.mpl"
	$include "Logout.mpl"
	$include "Utils.mpl"

    # 加载包时改变微分算子的显示方式
	ModuleLoad:=proc()	
		PDETools:-declare('quiet'):
	end proc;
	ModuleLoad();

    # 进行分类
    doClassify:=proc(vv::list)
		local As,A,eqs,sols,reps;
		As,A,eqs:=getTransMatAndPDE(vv);
		classify(A,As,eqs);
		sols:=getSols();
		reps:=buildReps(sols);
		return reps;
	end proc:

end module: