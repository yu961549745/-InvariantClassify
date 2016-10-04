# prepare lib
restart:
libname:=libname,"..":
with(MapleCodeReader):
# prepare data
ReadCode("../InvClassify/Basic.mpl");
setLogLevel(3);
vv:=[d(x), d(t), u*d(u), x*d(x)+2*t*d(t), 2*t*d(x)-x*u*d(u), 4*t*x*d(x)+4*t^2*d(t)-(x^2+2*t)*u*d(u)]:
As,A,eqs:=getTransMatAndPDE(vv):
# run test
ReadCode("../InvClassify/Closure.mpl");
map(findClosure,[seq(1..4)],[{2,3},{2},{3},{1,4}]);
getClosure(A);
getClosure(A,[a[2]=0,a[4]=0,a[6]=0]);
getClosure(A,[a[2]=0,a[4]=0,a[6]=0,a[1]=0,a[5]=0]);
