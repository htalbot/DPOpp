
#ifndef __TEST_XYZ_SERVER_VERSION_H__
#define __TEST_XYZ_SERVER_VERSION_H__

#define TEST_XYZ_SERVER_MAJOR       0
#define TEST_XYZ_SERVER_MINOR       0
#define TEST_XYZ_SERVER_PATCH       0


#if defined _MSC_VER
#   ifdef _DEBUG
        const char TEST_XYZ_SERVER_DebugFlag[] = "DEBUG";
#   else
        const char TEST_XYZ_SERVER_DebugFlag[] = "RELEASE";
#   endif
#else
#   ifdef DEBUG
        const char TEST_XYZ_SERVER_DebugFlag[] = "DEBUG";
#   else
        const char TEST_XYZ_SERVER_ebugFlag[] = "RELEASE";
#   endif
#endif


#endif // __TEST_XYZ_SERVER_VERSION_H__
