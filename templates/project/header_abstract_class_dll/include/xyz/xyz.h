
#ifndef XYZ_H
#define XYZ_H

#include "xyz/XYZ_Export.h"
#include "xyz/version.h"

namespace Xyz_ns
{
    class Xyz
    {
    public:

        // No-op virtual destructor.
        virtual ~Xyz()
        {
        }

        // Methods to define                                                    // <--
        virtual void fn() = 0;
        virtual void get_version(int & major,
                                    int & minor,
                                    int & patch) = 0;
    };

} // Xyz_ns namespace


#endif // XYZ_H
