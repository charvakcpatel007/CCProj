SET fileName=codeGenerator
flex %fileName%.l
bison -dy %fileName%.y
gcc Functions.h Functions.c lex.yy.c y.tab.c y.tab.h  -o %fileName%.exe -w
REM del lex.yy.c
REM del y.tab.c
REM del y.tab.h