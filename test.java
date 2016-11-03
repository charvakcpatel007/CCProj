
class A
{   
    A x;
    int a,b,c;
    void fx()
    {
       int d;
    }
}

class B
{
    A b;
    void fx()
    {
        A bin;
        bin.x.c = b.c;
    } 
}

