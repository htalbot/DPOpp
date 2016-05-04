
//******************************************************************************
// Declare and define these...

// Include the header of the interface to use as client
#include "relatedinterface/relatedinterfaceC.h"

// Define access method types
#define IORTABLE 0
#define NAMING_SERVICE 1

// Choose between IORTABLE and NAMING_SERVICE methods to
// get reference on an object.
//#define RESOLVE_WITH    IORTABLE
//#define RESOLVE_WITH    NAMING_SERVICE

// Use the relevant namespace
using namespace RELATEDINTERFACE_module;

// Include the ACE_Task header.
#include "ace/Task.h"
//******************************************************************************



// Inherit from ACE_Task_Base
class Xyz_ClientSide : public ACE_Task_Base
{
public:
    Xyz_ClientSide() {}

    //Set tao layer                                                             // <--
    void tao_layer(XyzTAOLayer * layer)
    {
        tao_layer_ = layer;
    }


protected:

    virtual int svc()
    {
        // Define the object ID.                                                // <--
        #define OBJ_REF_NAME  "obj_impl_ref_name";

        // Define the object location.                                          // <--
        char szRefLocation[] = "corbaloc:iiop:HOST:PORT/"OBJ_REF_NAME;

        // Declare Corba object reference.
        relatedinterface_var object;

        // Resolve reference according to access method.
        try
        {
        #if RESOLVE_WITH == NAMING_SERVICE
            object = tao_layer_->get_ref_from_ns<relatedinterface>
                                                                (OBJ_REF_NAME);
        #endif // NAMING_SERVICE

        #if RESOLVE_WITH == IORTABLE
            object = tao_layer_->
                        get_ref_from_iortable<interface_of_object_to_use>
                                                                (szRefLocation);
        #endif // IORTABLE
        }
        catch(...)
        {
            ACE_DEBUG((LM_ERROR, "Can not get reference on %s\n",
                                                                OBJ_REF_NAME));
            return -1;
        }


        // Use the object.
        for (int i = 0; i != 60; i++)
        {
            try
            {
                // Make sure to use the right interface                         // <--
                CORBA::Long value = object->get();
                ACE_DEBUG((LM_DEBUG, "value = %d\n", value));
            }
            catch(...)
            {
                ACE_DEBUG((LM_ERROR, "Can not use object %s\n", OBJ_REF_NAME));
            }

            ACE_OS::sleep(1);
        }

        return -1;
   }

    XyzTAOLayer * tao_layer_;
};

