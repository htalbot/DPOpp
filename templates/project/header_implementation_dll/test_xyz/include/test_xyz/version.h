
#ifndef __TEST_XYZ_VERSION_H__
#define __TEST_XYZ_VERSION_H__

#define TEST_XYZ_MAJOR       0
#define TEST_XYZ_MINOR       0
#define TEST_XYZ_PATCH       0


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


#endif // __TEST_XYZ_VERSION_H__
