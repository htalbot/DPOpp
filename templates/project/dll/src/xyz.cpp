
#include "xyz/xyz.h"
#include "xyz/version.h"

#include <stdio.h> // Needed?                                                   // <--

namespace Xyz_ns
{
    void xyz_get_version(int & major, int & minor, int & patch)
    {
        major = XYZ_MAJOR;
        minor = XYZ_MINOR;
        patch = XYZ_PATCH;
    }

    Xyz::Xyz(int value)
    :   m_value(value)
    {
        printf("Xyz::Xyz() - version = %d.%d.%d (%s)\n",
                XYZ_MAJOR,
                XYZ_MINOR,
                XYZ_PATCH,
                XYZ_DebugFlag);
    }

    void Xyz::show()
    {
        printf("Xyz::show() - value = %d\n",
                m_value);
        printf("\n");
    }
} // Xyz_ns namespace
