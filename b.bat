SET fileName=typeChecker
flex %fileName%.l
bison -dy %fileName%.y
gcc %fileName%.h lex.yy.c y.tab.c y.tab.h  -o %fileName%.exe -w
del lex.yy.c
del y.tab.c
del y.tab.h