#ifndef FUNC_H
#define FUNC_H
typedef struct arglist
{
    struct node* ptr;//Points to type of arg in sym table
    struct arglist* next;//for linked list purpose
} argListNode;

typedef struct snode
{
    int id;
    struct snode* next;
} sNode;
typedef struct node
{
    char* name;
    struct node* type;//in typetab it remains zero, for functions it states return type
    struct node* classPtr;//if memeber of class then points to the class else its null
    argListNode* args;// if not null then its a function with arg ll 
    struct node* next;
    int blockID;
} Node; 

Node* symtab;
Node* curClass;
Node* curFunction;
int curClassScope;
int line;
int nextID;
extern char* yytext; 

Node* add( Node* ll, char* s, int b_id );
void printLL( const Node* const ll );
Node* find( const Node* const ll, char* s );
Node* findDecl( const Node* const ll, char* s, int blockID );


void printArgList( const argListNode* const ll );
argListNode* addArg( argListNode* ll, struct node* ptr );
int isInScope( int symBlock );



sNode* stack;
void push();
void pop();
int getCurBlockID();
int genNextBlockID();

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