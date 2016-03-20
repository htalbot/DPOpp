
#ifndef XYZ_H
#define XYZ_H

#include "xyz/XYZ_Export.h"
#include "xyz/version.h"

// Include necessary includes                                                   // <--
#include <stdio.h>

namespace Xyz_ns
{
    class Xyz
    {
    public:

        // Define interface                                                     // <--
        virtual void fn()
        {
            printf("Xyz::fn()\n");
        }
    };
} // Xyz_ns namespace


#endif // XYZ_H
