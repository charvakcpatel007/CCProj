%{
#include "typeChecker.h" 
#include <stdio.h>
#include <math.h>  

%}
%union
{
    int val;
    double dval;
    struct node *symp;
    char* name;
}
%token <name> ID
%token <symp> CLASS
%token <symp> DATATYPE
%type <symp> E
%type <symp> IDI
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

CBLOCK : CBLOCK DECL {}
       | CBLOCK FUNC {}
       |             {}
       ;
/*Functions inside the class part*/
FUNC : DATATYPE ID             { 
                                   symtab = add( symtab, $2, getCurBlockID() );
                                   symtab->type = $1; 
                                   symtab->classPtr = curClass;
                               } 
       '('ARGORNULL')'           {
                                
                               } 
       '{'STATEMENTS '}'       {
           
                               }
     ;

ARGORNULL : ARGLIST             { }
          |                     { }
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
                                         }
                                      }
     ;
                                      
STATEMENTS : E ';' STATEMENTS     {}
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
                                }
                                else
                                {
                                    symtab->classPtr = NULL;
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
                                }
                                else
                                {
                                    symtab->classPtr = NULL;
                                }
                            }     
                          }
       ;
/****************************************/
/*Part which handles when id is refered*/      
E: IDI '=' E                         {
                                        if( $1 == $3 )
                                        {
                                            $$ = $3;
                                        }
                                        else
                                        {
                                            printf( "%s != %s", $1->name, $3->name );
                                            yyerror( "Not compatable types" );
                                            $$ = $3;
                                        }    
                                        
                                        
                                    }
 | IDI                              {
                                       $$ =  $1;
                                        
                                    }
 ;
                                    
IDI : IDI '.' ID                    {
                                        //Determine if it is accesable or not
                                        Node* itr;
                                        int found = 0;
                                        for( itr = symtab; itr != NULL; itr = itr->next )
                                        {
                                            if( strcmp( itr->name, $3 ) == 0 && itr->classPtr == $1 )
                                            {
                                                found = 1;
                                                break;
                                            }
                                        }
                                        if( found == 1 )
                                        {
                                            $$ = itr->type;
                                        }
                                        else
                                        {
                                            yyerror( "Not a member or in-compatatble types" );
                                            $$ = itr->type;
                                        }
                                        
                                    }
    | ID                            {
                                        Node* itr = find( symtab, $1 );
                                        if( itr == NULL )yyerror( "Not in scope " );
                                        else
                                        {
                                            $$ = itr->type;
                                        }
                                    }
    ;
/********************************************/
%%
//ID gets pointer to symtab so E gets its type


//ID name  directly points to the s provided so it should not be on stack or freed later on.
Node* add( Node* ll, char* s, int b_id )
{
    Node* newEntry = ( Node* )malloc( sizeof( Node ) );
    newEntry->name = s;
    newEntry->type = NULL;
    newEntry->classPtr = NULL;
    newEntry->next = ll;
    newEntry->blockID = b_id;
    return newEntry;
}


//It finds the symbol to all the outer + current scope declaration
Node* find( const Node* const ll, char* s )
{
    Node* itr = ll;
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        if( strcmp( s, itr->name ) == 0 && ( itr->blockID == 0 || ( isInScope( itr->blockID ) == 1 ) ) )
        {
            return itr;
        }
    }
    return NULL;
}

//use it when declaring , it just searches in current scope
Node* findDecl( const Node* const ll, char* s, int blockID )
{
    Node* itr = ll;
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        if( strcmp( s, itr->name ) == 0 && ( itr->blockID == 0 || ( blockID == itr->blockID ) ) )
        {
            return itr;
        }
    }
    return NULL;
}

void  main()
{
    symtab = NULL;
    line = 1;
    stack = NULL;
    curClass = NULL;
    nextID = 1;
    curClassScope = 0;
    int i = 0;
    char a[][10] = { "int", "float", "double", "byte", "char", "String", "void" };
    for( i = 0; i < 7; i++ )
    {
        symtab = add( symtab, a[ i ], 0 );
        
    }
    yyparse();
    printLL( symtab );
}

yyerror(const char *msg)
{
     printf("error : %s at line %d \n",msg, line );
}

void printLL( const Node* const ll )
{
    Node* itr = ll;
    printf( "<---Start--->\n" );
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        printf( "%s -- %d -- %s -- %s\n", itr->name
                                        , itr->blockID
                                        , ( itr->type == NULL ) ? "Type" : itr->type->name
                                        , ( itr->classPtr == NULL ) ? "Non-Member" : itr->classPtr->name
            );
        
    }
    printf( "<----End---->\n\n" );
}



//0th block is universal
int genNextBlockID()
{
    nextID++;
    return nextID - 1;
}

int getNextBlockID()
{
    return nextID;
}


void push()
{
    sNode* temp = ( sNode* )malloc( sizeof( sNode ) );
    temp->id = genNextBlockID();
    temp->next = stack;
    stack = temp;
}
void pop()
{
    if( stack == NULL )
    {
        yyerror( "Unbalanced Blocks" );
        return;
    }
    sNode* temp = stack;
    stack = stack->next;
    free(temp);
}
int getCurBlockID()
{
    if( stack == NULL )return 0;
    return stack->id;
}


//Checks if provided block_id of ID provided is in the scope or not
int isInScope( int symBlock )
{
    
    if( stack == NULL )
    {
        if( symBlock == 0 )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    sNode* temp = stack;
    for( ; temp != NULL; temp = temp->next )
    {
        
        if( symBlock == temp->id )
        {
            return 1;
        }
    }
    return 0;
} 