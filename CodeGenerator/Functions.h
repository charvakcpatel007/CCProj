#ifndef FUNC_H
#define FUNC_H

#include <stdio.h>
#include <math.h> 


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
    int as;//0 for private , 1 for public
    int isStatic;
} Node; 

Node* symtab;



Node* curClass;
Node* curFunction;
Node* voidTypePtr;
int lastAS;
int lastisStatic;
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
int isSameArgs( const argListNode* const l1, const argListNode* const l2 );
int isInScope( int symBlock );



sNode* stack;
void push();
void pop();
int getCurBlockID();
int genNextBlockID();

/************/
/*Structs to support code generation*/

typedef struct codeGenNode
{
    char* str;
    struct codeGenNode* next;
} CodeGenNode;

//string is passed by ref here but after than new copy is created so if old one is on heap, it should be freed
CodeGenNode* initCodeGenNode( char* str );
#ifndef cfl
#define cfl
//its a pair of two pointers nothing fancy here
struct codeFragLL
{
        struct codeGenNode* head;
        struct codeGenNode* tail;
};
#endif

typedef struct codeFragLL CodeFragLL;

void printCodeFragLL( const struct codeFragLL l1 );

struct codeFragLL addBackCodeFragLL( struct codeFragLL ll, char* str );

struct codeFragLL addFrontCodeFragLL( struct codeFragLL ll, char* str );

struct codeFragLL mergeCodeFragLL( struct codeFragLL l1, struct codeFragLL l2 );

/************/

#endif