# fun:=proc()
#     local cid:=0,getCname;
#     getCname:=proc()
#         cid:=cid+1;
#         return c[cid];
#     end proc:
#     return Array(1..6,getCname);
# end proc:
# fun();
# Array(3..5,x->a[x]);
{[1],[1,1],[1,2],[2]};