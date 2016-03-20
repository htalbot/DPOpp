
#pragma once

#include "xyz/XYZ_Export.h"
#include "xyz/version.h"


namespace Xyz_ns
{
    extern "C" XYZ_Export void xyz_get_version(int & major, int & minor, int & patch);

    class XYZ_Export Xyz
    {
    public:
        Xyz(int value);
        void show();

    private:
        int m_value;
    };
} // Xyz_ns namespace

