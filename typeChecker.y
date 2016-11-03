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
%%

P: CLS    {}
 | CLS P  {;}

CLS : CLASS ID { symtab = add( symtab, $2, getCurBlockID() ); } '{'CBLOCK'}'         { ; } 

CBLOCK : CBLOCK DECL {;}
       | CBLOCK FUNC {;}
       | CBLOCK CLS  {;}
       |             {;}
       ;

FUNC : DATATYPE ID       { symtab = add( symtab, $2, getCurBlockID() );symtab->type = $1; } '('')''{'STATEMENTS '}' {  }
     ;

STATEMENTS : E ';' STATEMENTS     {}
           | DECL  STATEMENTS     {  }
           | error STATEMENTS     {  }
           |                      {  }
           ;


DECL : DATATYPE IDLIST';' {} 
     ;

IDLIST : IDLIST ','ID     { 
                            Node* itr = findDecl( symtab, $3 );
                            if( itr != NULL )yyerror( "Re-declaration" );
                            else
                            {
                                symtab = add( symtab, $3, getCurBlockID() );
                                symtab->type = $<symp>0;
                            }
                          }
       | ID               {  
                            Node* itr = findDecl( symtab, $1 );
                            if( itr != NULL )yyerror( "Re-declaration" );
                            else
                            {
                                symtab = add( symtab, $1, getCurBlockID() );
                                symtab->type = $<symp>0;
                            }     
                          }
       ;

       
E: ID '=' E                         {
                                          
                                    }
 | ID                               {
                                        
                                    }



 ;

%%
//ID gets pointer to symtab so E gets its type


Node* add( Node* ll, char* s, int b_id )
{
    Node* newEntry = ( Node* )malloc( sizeof( Node ) );
    newEntry->name = (char*)malloc( strlen( s ) + 1 );
    newEntry->name = s;
    newEntry->type = NULL;
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

Node* findDecl( const Node* const ll, char* s )
{
    Node* itr = ll;
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        if( strcmp( s, itr->name ) == 0 && ( itr->blockID == 0 || ( getCurBlockID() == itr->blockID ) ) )
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
        if( itr->type == NULL )
        {
            printf( "%s -- %d\n", itr->name, itr->blockID );
        }
        else
        {
            printf( "%s -- %d -- %s\n", itr->name, itr->blockID, itr->type->name );
        }
    }
    printf( "<----End---->\n\n" );
}



//0th block is universal
int getNextBlockID()
{
    static int nextID = 1;
    nextID++;
    return nextID - 1;
}

void push()
{
    sNode* temp = ( sNode* )malloc( sizeof( sNode ) );
    temp->id = getNextBlockID();
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