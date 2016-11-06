#include "Functions.h"

//ID name  directly points to the s provided so it should not be on stack or freed later on.
Node* add( Node* ll, char* s, int b_id )
{
   
    Node* newEntry = ( Node* )malloc( sizeof( Node ) );
    newEntry->name = s;
    newEntry->type = NULL;
    newEntry->classPtr = NULL;
    newEntry->next = ll;
    newEntry->blockID = b_id;
    newEntry->args = NULL;
    newEntry->isStatic = 0;
    //printLL( newEntry );
    return newEntry;
}

void printLL( const Node* const ll )
{
    Node* itr = ll;
    printf( "<---Start--->\n" );
    printf( "%-8s %-10s %-6s %-15s %-10s %-13s %-20s\n", "Name"
                                                    , "Block ID"
                                                    , "TYPE"
                                                    , "Member of Class"
                                                    , "AS"
                                                    , "Instance"
                                                    , "ArgList Right-Left" );
    //printf( "Name -- Block ID -- TYPE -- Member of Class -- AS -- ArgList Right-Left\n" );
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        printf( "%-8s %-10d %-6s %-15s %-10s %-13s ", itr->name
                                        , itr->blockID
                                        , ( itr->type == NULL ) ? "Type" : itr->type->name
                                        , ( itr->classPtr == NULL ) ? "Non-Member" : itr->classPtr->name
                                        , ( itr->as == 0 ) ? "Private" : "Public"
                                        , ( itr->isStatic ) ?  "Static" : "Non-Static"
            );
        printArgList( itr->args );
        printf( "\n" );
    }
    printf( "<----End---->\n\n" );
}

void printArgList( const argListNode* const ll )
{
    const argListNode* itr = ll;
    for( itr = ll; itr != NULL; itr = itr->next )
    {
        printf( "%s ", itr->ptr->name );
    }
}
argListNode* addArg( argListNode* ll, struct node* ptr )
{
    argListNode* newEntry = (argListNode*)malloc( sizeof( argListNode ) );
    newEntry->next = ll;
    newEntry->ptr = ptr;
    return newEntry;
}

int isSameArgs( const argListNode* const l1, const argListNode* const l2 )
{
    const argListNode* itr1 = l1;
    const argListNode* itr2 = l2;
    for( ;1;itr1 = itr1->next, itr2 = itr2->next )
    {
        if( itr1 == NULL && itr2 == NULL )
        {
            return 1;
        }
        if( itr1 == NULL || itr2 == NULL )
        {
            return 0;
        }
        if( itr1->ptr != itr2->ptr )
        {
            return 0;
        }
    }
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

yyerror(const char *msg)
{
     printf("error : %s at line %d \n",msg, line );
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