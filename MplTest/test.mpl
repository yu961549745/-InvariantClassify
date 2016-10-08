x:=[1,2,3];
c:=0;
getCname:=proc()
    global c;
    c:=c+1;
    return delta[c];
end proc:
seq(x[i]=getCname(),i=1..3);