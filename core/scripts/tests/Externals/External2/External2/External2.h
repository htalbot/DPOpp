// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the EXTERNAL2_EXPORTS
// symbol defined on the command line. This symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// EXTERNAL2_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef _USRDLL
#ifdef EXTERNAL2_EXPORTS
#define EXTERNAL2_API __declspec(dllexport)
#else
#define EXTERNAL2_API __declspec(dllimport)
#endif
#else
#define EXTERNAL2_API 
#endif

// This class is exported from the External2.dll
class EXTERNAL2_API CExternal2 {
public:
	CExternal2(void);
	void show(int);
};

