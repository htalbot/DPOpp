
#include "test_xyzAppLayer.h"
#include "xyz/xyz.h"

using namespace Xyz_ns;

#include <stdio.h>

#if defined _MSC_VER
#   ifdef _DEBUG
        const char TEST_XYZ_DebugFlag[] = "DEBUG";
#   else
        const char TEST_XYZ_DebugFlag[] = "RELEASE";
#   endif
#else
#   ifdef DEBUG
        const char TEST_XYZ_DebugFlag[] = "DEBUG";
#   else
        const char TEST_XYZ_DebugFlag[] = "RELEASE";
#   endif
#endif

Test_xyzAppLayer::Test_xyzAppLayer()
{
}


bool Test_xyzAppLayer::run()
{
    printf("***** Test_xyzAppLayer (%s) *****\n\n", TEST_XYZ_DebugFlag);

    int major, minor, patch;
    xyz_get_version(major, minor, patch);
    printf("xyz version: %d.%d.%d\n", major, minor, patch);

    Xyz_ns::Xyz obj(88);
    obj.show();

    return true;
}

