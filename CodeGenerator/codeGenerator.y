%{

#include <stdio.h>
#include <math.h>  
#include "Functions.h" 

%}
%union
{
    int val;
    double dval;
    struct node *symp;
    char* name;
    struct arglist* argp;
    #ifndef cfl
    #define cfl
    //its a pair of two pointers nothing fancy here
    struct codeFragLL
    {
        struct codeGenNode* head;
        struct codeGenNode* tail;
    };
    #endif
    struct codeFragLL codeFrag;
}
%type <codeFrag> E
%type <codeFrag> STATEMENTS
%type <codeFrag> IDI
%type <codeFrag> FUNC
%type <codeFrag> ARGORNULL
%token <name> ID
%token <symp> CLASS
%token <symp> DATATYPE
%token <val> STATIC
%token <val> AS

%type <codeFrag> FCALLARGS
%type <codeFrag> CALLARGLIST
%type <val> STATICORNULL

%%

P: CLS    {}
 | CLS P  {;}
 ;
CLS : CLASS ID           { 
                            curClass = symtab = add( symtab, $2, getCurBlockID() );
                            /*
                            For the declarations that are going to come
                            scope for them will be whatever the value of scope after '{' will be so we set right here.
                            */
                            curClassScope = getNextBlockID();
                         } 
    '{'CBLOCK'}'         { ; } 

CBLOCK : CBLOCK AS STATICORNULL DECL       {  }
       | CBLOCK FUNC                       {  }
       |                                   {  }
       ;
/*Functions inside the class part*/
FUNC : AS STATICORNULL DATATYPE ID          { 
                                                symtab = add( symtab, $4, getCurBlockID() );
                                                symtab->type = $3; 
                                                symtab->classPtr = curClass;
                                                symtab->as = lastAS;//assign lastAS
                                                symtab->isStatic = lastisStatic;
                                                curFunction = symtab;
                                                
                                            } 
       '(' ARGORNULL ')'                    {
                                                if( curFunction->args == NULL )
                                                {
                                                    curFunction->args = addArg( curFunction->args, voidTypePtr );
                                                }
                                                
                                            } 
       '{' STATEMENTS '}'                   {
                                                
                                                printCodeFragLL( $11 );
                                            }
     ;

ARGORNULL : ARGLIST             { }
          |                     {  }
          ;
ARGLIST : ARGLIST ',' ARG             {
                                        
                                         
                                      }
        | ARG                         { }
        ;
                                     
ARG : DATATYPE ID                     {
                                         /*Since '{' isnt encountered it is still not in the scope of fucntion so byte
                                         calling next we get that scope id*/
                                         Node* itr = findDecl( symtab, $2, getNextBlockID() );
                                         if( itr != NULL )yyerror( "Re-declaration" );
                                         else
                                         {
                                             symtab = add( symtab, $2, getNextBlockID() );
                                             symtab->type = $1;
                                             //Well they are clearly not a member of a class.
                                             symtab->classPtr = NULL;
                                             curFunction->args = addArg( curFunction->args, $1 );   
                                         }
                                      }
     ;
                                      
STATEMENTS : E ';' STATEMENTS     { 
                                      $1 = addBackCodeFragLL( $1, ";\n" );
                                      $$ = mergeCodeFragLL( $1, $3 );
                                       
                                  }
           | DECL  STATEMENTS     {  }
           | error STATEMENTS     {  }
           |                      { 
                                    struct codeFragLL temp = { NULL, NULL };
                                    $$ =  temp;
                                  }
           ;
/************************************/

/****************************************/
/*Part which handles when id is refered*/      
E: IDI '=' E                        {
                                        
                                        $1 = addBackCodeFragLL( $1, "=" ); 
                                       
                                        $$ = mergeCodeFragLL( $1, $3 );
                                    }
 | IDI                              {
                                        $$ = $1;
                                    }
 ;
                                    
IDI : IDI '.' ID FCALLARGS          {
                                        $1 = addBackCodeFragLL( $1, "." );
                                        $1 = addBackCodeFragLL( $1, $3 );
                                        free( $3 );
                                        $$ = mergeCodeFragLL( $1, $4 );
                                        
                                    }
    | ID FCALLARGS                  {
                                        $2 = addFrontCodeFragLL( $2, $1 );
                                        free( $1 );
                                        $$ = $2;
                                    }
    ;
FCALLARGS : '('CALLARGLIST')'       {
                                        $2 = addFrontCodeFragLL( $2, "(" );
                                        $2 = addBackCodeFragLL( $2, ")" );
                                        $$ = $2;
                                    }
          | '('')'                  {
                                        CodeFragLL temp = { NULL, NULL };
                                        temp = addBackCodeFragLL( temp, "()" );
                                        $$ = temp;
                                    }
          |                         {
                                        CodeFragLL temp = { NULL, NULL };
                                        $$ = temp;
                                    }
CALLARGLIST : CALLARGLIST ',' IDI   {
                                        $1 = addBackCodeFragLL( $1, ", " );
                                        $$ = mergeCodeFragLL( $1, $3 );
                                    }
            | IDI                   {
                                        $$ = $1;
                                    }
/********************************************/

/*Declaration Is Taken care combined for types and ids*/
DECL : DATATYPE IDLIST';' {} 
     ;
IDLIST : IDLIST ','ID     { 
                            Node* itr = findDecl( symtab, $3, getCurBlockID() );
                            if( itr != NULL )yyerror( "Re-declaration" );
                            else
                            {
                                symtab = add( symtab, $3, getCurBlockID() );
                                symtab->type = $<symp>0;
                                /*if current scope is class scope then
                                its member of that class so set up class pointer 
                                unless its just a normal decl inside*/
                                if( curClassScope == getCurBlockID() )
                                {
                                    symtab->classPtr = curClass;
                                    symtab->as = lastAS;//assign lastAS
                                    symtab->isStatic = lastisStatic;
                                }
                                else
                                {
                                    symtab->classPtr = NULL;
                                    symtab->as = 0;//they are private
                                    symtab->isStatic = lastisStatic;
                                }
                            }
                          }
       | ID               {  
                            Node* itr = findDecl( symtab, $1, getCurBlockID() );
                            if( itr != NULL )yyerror( "Re-declaration" );
                            else
                            {
                                symtab = add( symtab, $1, getCurBlockID() );
                                symtab->type = $<symp>0;
                                if( curClassScope == getCurBlockID() )
                                {
                                    symtab->classPtr = curClass;
                                    symtab->as = lastAS;//assign lastAS
                                    symtab->isStatic = lastisStatic;
                                }
                                else
                                {
                                    symtab->classPtr = NULL;
                                    symtab->as = 0;//they are private
                                    symtab->isStatic = lastisStatic;
                                }
                            }     
                          }
       ;
       
STATICORNULL : STATIC           {  }
              |                 {  }

%%



void  main()
{
    symtab = NULL;
    line = 1;
    stack = NULL;
    curClass = NULL;
    curFunction = NULL;
    voidTypePtr = NULL;
    nextID = 1;
    lastAS = 0;
    lastisStatic = 0;
    curClassScope = 0;
    int i = 0;
    char a[][10] = { "int", "float", "double", "byte", "char", "String", "void" };
    for( i = 0; i < 7; i++ )
    {
        symtab = add( symtab, a[ i ], 0 );
        
    }
    voidTypePtr = symtab;
    
    yyparse();
    printLL( symtab );
}

 