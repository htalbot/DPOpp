// External1.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "External1.h"
#include <stdio.h>


// This is the constructor of a class that has been exported.
// see External1.h for the class definition
CExternal1::CExternal1()
{
	return;
}

void CExternal1::show(int value)
{
    printf("External1: value = %d\n", value);
}
