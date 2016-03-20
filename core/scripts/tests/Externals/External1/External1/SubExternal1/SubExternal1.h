// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the EXTERNAL1_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// EXTERNAL1_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef _USRDLL
#ifdef EXTERNAL1_EXPORTS
#define EXTERNAL1_API __declspec(dllexport)
#else
#define EXTERNAL1_API __declspec(dllimport)
#endif
#else
#define EXTERNAL1_API
#endif

// This class is exported from the External1.dll
class EXTERNAL1_API CExternal1 {
public:
	CExternal1(void);
	
    void show(int);
};

