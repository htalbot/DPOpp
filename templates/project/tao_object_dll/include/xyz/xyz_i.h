
#ifndef XYZ_I_H
#define XYZ_I_H

#include "XYZ_Export.h"
#include "version.h"

#include "relatedinterface/relatedinterfaceS.h"
#include "relatedinterface/relatedinterfaceC.h"

extern "C" XYZ_Export void xyz_get_version(int & major, int & minor, int & patch);

class XYZ_Export Xyz_i : public POA_RELATEDINTERFACE_ns::Relatedinterface
{
public:
    Xyz_i();
    ~Xyz_i();

    virtual CORBA::Long get();
};

#endif /* XYZ_I_H */


