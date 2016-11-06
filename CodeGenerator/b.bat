SET fileName=codeGenerator
flex %fileName%.l
bison -dy %fileName%.y
gcc Functions.h Functions.c lex.yy.c y.tab.c y.tab.h  -o %fileName%.exe -w
del lex.yy.c
del y.tab.c
del y.tab.h