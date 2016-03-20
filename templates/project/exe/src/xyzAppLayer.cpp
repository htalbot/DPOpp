
#include "xyzAppLayer.h"
#include "xyz/version.h"
#include <stdio.h>

XyzAppLayer::XyzAppLayer()
{
}


int XyzAppLayer::run()
{
    printf("XyzAppLayer - version: %d.%d.%d (%s)\n",
            XYZ_MAJOR,
            XYZ_MINOR,
            XYZ_PATCH,
            XYZ_DebugFlag);
    printf("\n");

    return 0;
}

