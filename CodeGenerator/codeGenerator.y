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
%type <codeFrag> CBLOCK
%type <codeFrag> ARGLIST 
%type <codeFrag> ARG
%type <codeFrag> IDLIST
%type <codeFrag> DECL


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
    '{'CBLOCK'}'         {
                            CodeFragLL temp = { NULL, NULL };
                            temp = addBackCodeFragLL( temp, "struct ");
                            temp = addBackCodeFragLL( temp, $2 );
                            temp = addBackCodeFragLL( temp, "\n{\n\t" );
                            temp = mergeCodeFragLL( temp, $5 );
                            temp = addBackCodeFragLL( temp, "\r}\n" );
                            printCodeFragLL( temp );
                         } 
    ;

CBLOCK : CBLOCK AS STATICORNULL DECL       { 
                                               declPartialToFinalCodeFrag( $4, $3, curClass->name );
                                               
                                               if( $3 == 1 )//static
                                               {
                                                   $4 = addBackCodeFragLL( $4, ";\n" );
                                                   globalVariables = mergeCodeFragLL( globalVariables, $4 );//static so send to global pool
                                                   $$ = $1;
                                               }
                                               else
                                               {
                                                   $4 = addBackCodeFragLL( $4, ";\n\t" );
                                                   $$ = mergeCodeFragLL( $$, $4 );
                                               }
                                               
                                           }
       | CBLOCK FUNC                       { 
                                                $$ = $1;
                                                functions = mergeCodeFragLL( functions, $2 );//send them to global pool
                                           }
       |                                   {
                                                CodeFragLL temp = { NULL, NULL };
                                                $$ = temp;
                                           }
       ;
/*Functions inside the class part*/
FUNC : AS STATICORNULL DATATYPE ID          { 
                                                
                                                symtab = add( symtab, $4, getCurBlockID() );
                                                symtab->type = $3; 
                                                symtab->classPtr = curClass;
                                                symtab->as = lastAS;//assign lastAS
                                                symtab->isStatic = lastisStatic;
                                                symtab->args = NULL;
                                                curFunction = symtab;
                                                
                                            } 
       '(' ARGORNULL ')'                    {
                                                if( curFunction->args == NULL )
                                                {
                                                    curFunction->args = addArg( curFunction->args, voidTypePtr );
                                                }
                                                
                                            } 
       '{' STATEMENTS '}'                   {
                                                CodeFragLL temp = { NULL, NULL };
                                                temp = addBackCodeFragLL( temp, $3->name );
                                                temp = addBackCodeFragLL( temp, " " );
                                                
                                                temp = addBackCodeFragLL( temp, curClass->name );
                                                temp = addBackCodeFragLL( temp, "_" );
                                                
                                                temp = addBackCodeFragLL( temp, $4 );
                                                temp = addBackCodeFragLL( temp, "( " );
                                                if( curFunction->isStatic == 0 )//not static
                                                {
                                                    if( $7.head == NULL )
                                                    {
                                                        $7 = addFrontCodeFragLL( $7, "* thisObj" );
                                                    }
                                                    else
                                                    {
                                                        $7 = addFrontCodeFragLL( $7, "* thisObj, " );
                                                    }
                                                    
                                                    $7 = addFrontCodeFragLL( $7, curClass->name );
                                                }
                                                
                                                temp = mergeCodeFragLL( temp, $7 );
                                                temp = addBackCodeFragLL( temp, " )\n{\n\t" );
                                                temp = mergeCodeFragLL( temp, $11 );
                                                temp = addBackCodeFragLL( temp, "\n}\n" );
                                                
                                                $$ = temp;
                                                
                                                
                                            }
     ;

ARGORNULL : ARGLIST             { 
                                    $$ = $1;
                                }
          |                     { 
                                    CodeFragLL temp = { NULL, NULL };
                                    $$ = temp;
                                }
          ;
ARGLIST : ARGLIST ',' ARG             {
                                          $1 = addBackCodeFragLL( $1, ", " );
                                          $$ = mergeCodeFragLL( $1, $3 );
                                      }
        | ARG                         { $$ = $1; }
        ;
                                     
ARG : DATATYPE ID                     {
    
                                         /*Since '{' isnt encountered it is still not in the scope of fucntion so byte
                                         calling next we get that scope id*/
                                         Node* itr = findDecl( symtab, $2, getNextBlockID() );
                                         CodeFragLL temp = { NULL, NULL };
                                        
                                         
                                         if( itr != NULL )yyerror( "Re-declaration" );
                                         else
                                         {
                                             symtab = add( symtab, $2, getNextBlockID() );
                                             symtab->type = $1;
                                             //Well they are clearly not a member of a class.
                                             symtab->classPtr = NULL;
                                             curFunction->args = addArg( curFunction->args, $1 );   
                                         }
                                         /*Code Generation Part*/
                                         temp = addBackCodeFragLL( temp, $1->name );
                                         temp = addBackCodeFragLL( temp, " " );
                                         temp = addBackCodeFragLL( temp, $2 );
                                         
                                         $$ = temp;
                                      }
     ;
                                      
STATEMENTS : E ';' STATEMENTS     { 
                                      $1 = addBackCodeFragLL( $1, ";\n\t" );
                                      $$ = mergeCodeFragLL( $1, $3 );
                                       
                                  }
           | DECL  STATEMENTS     { 
                                    declPartialToFinalCodeFrag( $1, 0/*its non-member so static*/, curClass->name );
                                    $1 = addBackCodeFragLL( $1, ";\n\t" );
                                    
                                    $$ = mergeCodeFragLL( $1, $2 ); 
                                    
                                    
                                  }
           | error STATEMENTS     {  }
           |                      { 
                                    CodeFragLL temp = { NULL, NULL };
                                    $$ = temp;
                                  }
           | ';' STATEMENTS       {
                                      $$ = addBackCodeFragLL( $2, ";" );;
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
                                        $1 = addBackCodeFragLL( $1, "->" );
                                        $1 = addBackCodeFragLL( $1, $3 );
                                        free( $3 );
                                        $$ = mergeCodeFragLL( $1, $4 );
                                        
                                    }
    | ID FCALLARGS                  {
                                        Node* itr = find( symtab, $1 );
                                        $2 = addFrontCodeFragLL( $2, $1 );
                                        if( itr->classPtr == NULL )
                                        {
                                            
                                        }
                                        else
                                        {
                                            if( itr->isStatic == 1 )//variable is static
                                            {
                                                $2 = addFrontCodeFragLL( $2, "_" );
                                                $2 = addFrontCodeFragLL( $2, itr->classPtr->name );
                                            }
                                            else
                                            {
                                                $2 = addFrontCodeFragLL( $2, "thisObj->" );
                                            }
                                            
                                                
                                            
                                        }
                                        
                                        free( $1 );
                                        $$ = $2;
                                    }
    | DATATYPE '.' ID FCALLARGS     {
                                        CodeFragLL temp = { NULL, NULL };
                                        temp = addBackCodeFragLL( temp, $1->name );
                                        temp = addBackCodeFragLL( temp, "_" );
                                        temp = addBackCodeFragLL( temp, $3 );
                                        temp = mergeCodeFragLL( temp, $4 );
                                        $$ = temp;
                                        free( $3 );
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
          ;
CALLARGLIST : CALLARGLIST ',' IDI   {
                                        $1 = addBackCodeFragLL( $1, ", " );
                                        $$ = mergeCodeFragLL( $1, $3 );
                                    }
            | IDI                   {
                                        $$ = $1;
                                    }
            ;
/********************************************/

/*its sends first node as type name and then each node is ID name*/
DECL : DATATYPE IDLIST';' {
                              $2 = addFrontCodeFragLL( $2, $1->name );
                              
                              $$ = $2;
                          } 
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
                            $1 = addBackCodeFragLL( $1, $3 );
                            $$ = $1;
                          }
       | ID               {  
                            CodeFragLL temp = { NULL, NULL };
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
                            temp = addBackCodeFragLL( temp, $1 );
                            $$ = temp;
                          }
       ;
       
STATICORNULL : STATIC           { $$ = 1; lastisStatic = 1; }
              |                 { $$ = 0; lastisStatic = 0; }
              ;

%%



void  main()
{
    symtab = NULL;
    line = 1;
    stack = NULL;
    curClass = NULL;
    curFunction = NULL;
    voidTypePtr = NULL;
    functions.head = NULL;
    functions.tail = NULL;
    globalVariables.head = NULL;
    globalVariables.tail = NULL;
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
    //printLL( symtab );
    printCodeFragLL( globalVariables );
    printCodeFragLL( functions );
    
}

 