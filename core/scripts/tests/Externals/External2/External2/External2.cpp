// External2.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "External2.h"
#include <stdio.h>


// This is the constructor of a class that has been exported.
// see External2.h for the class definition
CExternal2::CExternal2()
{
	return;
}

void CExternal2::show(int value)
{
    printf("CExternal2::show() - value = %d\n", value);
	return;
}
