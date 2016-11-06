%{
#include "Functions.h" 
#include <stdio.h>
#include <math.h>  

%}
%union
{
    int val;
    double dval;
    struct node *symp;
    char* name;
    struct arglist* argp;
}
%token <name> ID
%token <symp> CLASS
%token <symp> DATATYPE
%token <val> STATIC
%token <val> AS
%type <symp> E
%type <symp> IDI
%type <argp> FCALLARGS
%type <argp> CALLARGLIST
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
       '('ARGORNULL')'                      {
                                                if( curFunction->args == NULL )
                                                {
                                                    curFunction->args = addArg( curFunction->args, voidTypePtr );
                                                }
                                            } 
       '{'STATEMENTS '}'                    {
           
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
                                      
STATEMENTS : E ';' STATEMENTS     {  }
           | DECL  STATEMENTS     {  }
           | error STATEMENTS     {  }
           |                      {  }
           ;
/************************************/

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
       
STATICORNULL : STATIC           { $$ = 1; lastisStatic = 1; }
              |                 { $$ = 0; lastisStatic = 0;}
/****************************************/
/*Part which handles when id is refered*/      
E: IDI '=' E                        {
                                        if( $1 == $3 )
                                        {
                                            $$ = $3;
                                        }
                                        else
                                        {
                                            printf( "%s != %s ", $1->name, $3->name );
                                            yyerror( "Not compatable types" );
                                            $$ = $3;
                                        }    
                                    }
 | IDI                              {
                                       $$ =  $1;  
                                    }
 ;
                                    
IDI : IDI '.' ID FCALLARGS          {
                                        //Determine if it is accesable or not
                                        Node* itr;
                                        int found = 0;
                                        for( itr = symtab; itr != NULL; itr = itr->next )
                                        {
                                            if( strcmp( itr->name, $3 ) == 0 && itr->classPtr == $1 && itr->as == 1/*i.e it should be public*/ )
                                            {
                                                found = 1;
                                                break;
                                            }
                                        }
                                        if( found == 1 )
                                        {
                                            $$ = itr->type;
                                            //Get the linked list of called types
                                            if( isSameArgs( $4, itr->args ) == 0 )
                                            {
                                                yyerror( "Arguments Doesnt match" );
                                            }
                                            
                                        }
                                        else
                                        {
                                            yyerror( "Not a member or in-compatatble types" );
                                            $$ = $1;
                                        }
                                        
                                    }
    | ID FCALLARGS                   {
                                        Node* itr = find( symtab, $1 );
                                        if( itr == NULL )yyerror( "Not in scope " );
                                        else
                                        {
                                            $$ = itr->type;
                                            if( isSameArgs( $2, itr->args ) == 0 )
                                            {
                                                yyerror( "Arguments Doesnt match" );
                                            }
                                        }
                                    }
    ;
FCALLARGS : '('CALLARGLIST')'       {
                                        $$ = $2;
                                    }
          | '('')'                  {
                                        $$ = addArg( NULL, voidTypePtr );
                                    }
          |                         {
                                        $$ = NULL;
                                    }
CALLARGLIST : CALLARGLIST ',' IDI   {
                                        $$ = addArg( $1, $3 );
                                    }
            | IDI                   {
                                        $$ = addArg( NULL, $1 );
                                    }
/********************************************/
%%
//ID gets pointer to symtab so E gets its type



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

 