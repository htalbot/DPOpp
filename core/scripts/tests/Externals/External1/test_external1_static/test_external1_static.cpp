// test_external1_static.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "../External1/External1.h"

int _tmain(int argc, _TCHAR* argv[])
{
    CExternal1 ext1;
    ext1.show(27);

	return 0;
}

