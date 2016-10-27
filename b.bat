SET fileName=prac
flex %fileName%.l
bison -dy %fileName%.y
gcc func.h lex.yy.c y.tab.c y.tab.h  -o %fileName%.o -w