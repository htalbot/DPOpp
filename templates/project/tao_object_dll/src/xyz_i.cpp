
#include "xyz/xyz_i.h"

void xyz_get_version(int & major, int & minor, int & patch)
{
    major = XYZ_MAJOR;
    minor = XYZ_MINOR;
    patch = XYZ_PATCH;
}

Xyz_i::Xyz_i()
{
}

Xyz_i::~Xyz_i()
{
}

CORBA::Long Xyz_i::get()
{
    static long i(0);
    printf("Xyz_i get(%ld)...\n", i);

    return i++;
}

