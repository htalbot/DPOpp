
#include "xyz/related_object_i.h"

Related_object_i::Related_object_i()
{
}

Related_object_i::~Related_object_i()
{
}

CORBA::Long Related_object_i::get()
{
    static long i(0);
    printf("Related_object_i get(%ld)...\n", i);

    return i++;
}

