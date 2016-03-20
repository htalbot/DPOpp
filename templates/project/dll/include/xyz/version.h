
#pragma once

#define XYZ_MAJOR       0
#define XYZ_MINOR       0
#define XYZ_PATCH       0


#if defined _MSC_VER
#   ifdef _DEBUG
        const char XYZ_DebugFlag[] = "DEBUG";
#   else
        const char XYZ_DebugFlag[] = "RELEASE";
#   endif
#else
#   ifdef DEBUG
        const char XYZ_DebugFlag[] = "DEBUG";
#   else
        const char XYZ_DebugFlag[] = "RELEASE";
#   endif
#endif


