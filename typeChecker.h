#ifndef FUNC_H
#define FUNC_H
typedef struct node
{
    char* name;
    struct node* type;//in typetab it remains zero
    struct node* classptr;
    struct node* next;
    int blockID;
} Node; 

Node* symtab;
int line;
extern char* yytext; 

Node* add( Node* ll, char* s, int b_id );

Node* find( const Node* const ll, char* s );
Node* findDecl( const Node* const ll, char* s );

void printLL( const Node* const ll );

int isInScope( int symBlock );

typedef struct snode
{
    int id;
    struct snode* next;
} sNode;

sNode* stack;
void push();
void pop();
int getCurBlockID();
int getNextBlockID();

/*
P: CLS    {}
 | CLS P  {;}

CLS : CLASS ID'{'CBLOCK'}' { } 

CBLOCK : DECL CBLOCK {;}
       | FUNC CBLOCK {;}
       | DECL        {;}
       | FUNC        {;}

DECL : DATATYPE IDLIST';' {} 

IDLIST : ID','IDLIST     { symLast->typeId = curDataType; }
       | ID              { symLast->typeId = curDataType; }

FUNC : DATATYPE ID'('')''{ 'STATEMENTS '}' {  }

*/
#endif