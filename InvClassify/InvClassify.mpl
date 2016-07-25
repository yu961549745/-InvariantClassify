InvClassify:=module()
	option	package;
	local	Basic,
			Classifyer,
			Condition,
			Fetch,
			InvOrder,
			ObjUnique,
			Combine,
			getTransformMatrixAndPDE,
			getInvariants,
			sortByComplexity,
			findSolutionDomain,
			findInvariantsOrder,
			classify,
			classifySolve,
			collectObj;
	export	doClassify,
			InvSol,
			RepSol,
			getReps,
			addReps,
			rmRep,
			updateRep,
			summary,
			d,
			getSymbols,
			setSymbols,
			getSols,
			getNewSols,
			printSols,
			resolve,
			solveTeq,
			fetchSimpleSolution,
			printReps;

	$include "Basic.mpl"
	$include "Condition.mpl"
	$include "Classifyer.mpl"
	$include "Fetch.mpl"
	$include "InvOrder.mpl"
	$include "InvSol.mpl"
	$include "RepSol.mpl"
	$include "ObjUnique.mpl"
	$include "Combine.mpl"

	getTransformMatrixAndPDE:=Basic:-getTransformMatrixAndPDE;
	getInvariants:=Basic:-getInvariants;
	sortByComplexity:=Basic:-sortByComplexity;
	findSolutionDomain:=Condition:-findSolutionDomain;
	fetchSimpleSolution:=Fetch:-fetchSimpleSolution;
	findInvariantsOrder:=InvOrder:-findInvariantsOrder;
	classify:=Classifyer:-classify;
	classifySolve:=Condition:-classifySolve;
	printReps:=Combine:-printReps;

	d:=Basic:-d;
	getSymbols:=Basic:-getSymbols;
	setSymbols:=Basic:-setSymbols;
	getSols:=Classifyer:-getSols;
	getNewSols:=Classifyer:-getNewSols;
	printSols:=Classifyer:-printSols;
	resolve:=Classifyer:-resolve;
	solveTeq:=Classifyer:-solveTeq;
	collectObj:=ObjUnique:-collectObj;

	doClassify:=proc(vv::list)
		local As,A,eqs;
		As,A,eqs:=getTransformMatrixAndPDE(vv);
		classify(A,As,eqs);
	end proc:

	getReps:=Combine:-getReps;
	addReps:=Combine:-addReps;
	summary:=Combine:-summary;
	rmRep:=Combine:-rmRep;
	updateRep:=Combine:-updateRep;

end module: