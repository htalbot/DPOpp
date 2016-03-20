#ifndef XYZ_RELATED_OBJECT_I_H__
#define XYZ_RELATED_OBJECT_I_H__

#include "XYZ_Export.h"

#include "relatedinterface/relatedinterfaceS.h"
#include "relatedinterface/relatedinterfaceC.h"

class XYZ_Export Related_object_i : public POA_RELATEDINTERFACE_ns::Relatedinterface
{
public:
    Related_object_i();
    ~Related_object_i();

    virtual CORBA::Long get();
};

#endif /* XYZ_RELATED_OBJECT_I_H__ */


