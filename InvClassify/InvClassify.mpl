InvClassify:=module()
	option	package;
	local	Basic,
			Classifyer,
			Condition,
			Fetch,
			InvOrder,
			getTransformMatrixAndPDE,
			getInvariants,
			sortByComplexity,
			findSolutionDomain,
			findInvariantsOrder,
			classify;
	export	doClassify,
			InvSol,
			d,
			getSymbols,
			setSymbols,
			getSols,
			printSol,
			printSols,
			resolve,
			solveTeq,
			printTeq,
			fetchSimpleSolution;

	$include "Basic.mpl"
	$include "Condition.mpl"
	$include "Classifyer.mpl"
	$include "Fetch.mpl"
	$include "InvOrder.mpl"
	$include "InvSol.mpl"

	getTransformMatrixAndPDE:=Basic:-getTransformMatrixAndPDE;
	getInvariants:=Basic:-getInvariants;
	sortByComplexity:=Basic:-sortByComplexity;
	findSolutionDomain:=Condition:-findSolutionDomain;
	fetchSimpleSolution:=Fetch:-fetchSimpleSolution;
	findInvariantsOrder:=InvOrder:-findInvariantsOrder;
	classify:=Classifyer:-classify;

	d:=Basic:-d;
	getSymbols:=Basic:-getSymbols;
	setSymbols:=Basic:-setSymbols;
	getSols:=Classifyer:-getSols;
	printSol:=Classifyer:-printSol;
	printSols:=Classifyer:-printSols;
	resolve:=Classifyer:-resolve;
	solveTeq:=Classifyer:-solveTeq;
	printTeq:=Classifyer:-printTeq;

	doClassify:=proc(vv::list)
		local As,A,eqs;
		As,A,eqs:=getTransformMatrixAndPDE(vv);
		classify(A,As,eqs);
	end proc:

end module: