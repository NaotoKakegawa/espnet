#!/bin/csh -f
# csh ./lab2binacc.qst.fb.4dur.sh [input fullcontext label file]

set SRC = $0:h

set lbl = $1

cat $1 | \
awk '{a[NR]=$0;}END{for(i=1;i<=NR;i++){if(i==1){split(a[i],b,/ /); print 0,b[2],b[3];}else if(i==NR){split(a[i],b,/ /); print b[1],b[2],b[3];}else{print a[i];}}}' | \
tac | \
awk '{split($3,prs,/\//); gsub(/C:/,"",prs[4]); gsub(/-/,"_",prs[4]); gsub(/+/,"_",prs[4]); split(prs[2], aa, /_/); split(prs[4], cc, /_/); if(cc[9]=="x" || out=="x"){out=cc[9];}else if(out>=cc[9]){out=out;}print $0,out;}' | \
tac | \
$SRC/lab2binacc.qst.fb.4dur.awk

