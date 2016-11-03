%{
#include<stdio.h>
#include"y.tab.h"

#include "typeChecker.h"

%}
%option noyywrap
%%
"."                                                          { return yytext[ 0 ]; }
"{"                                                         { push(); return yytext[0]; } 
"}"                                                         { pop(); return yytext[0];  }
"\n"                                                        { line++; }
" "|"\t"                                                    {;}
"class "             					    				{ return CLASS; }
([_a-zA-z][0-9]*)+                                          {
                                                                Node* temp = find( symtab, yytext );
																yylval.name = (char*) malloc( strlen( yytext ) + 1 );
                                                                strcpy( yylval.name, yytext );
                                                                    
                                                                if( temp == NULL ) 
                                                                {
                                                                    return ID;
                                                                }
                                                                else
                                                                {
                                                                    if( temp->type == NULL )
                                                                    {
                                                                        yylval.symp = temp;
                                                                        return DATATYPE;
                                                                    }
                                                                    else
                                                                    {
                                                                        return ID;
                                                                    }
                                                                }
															}
.                                                           { return yytext[0];}
%%


