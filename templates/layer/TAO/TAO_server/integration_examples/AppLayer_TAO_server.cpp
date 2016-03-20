
//******************************************************************************
// Declare and define these...                                                  // <--

// Include the object header (object to activate).
#include "related_object_host/related_object_i.h"

// Define access method types
#define IORTABLE 0
#define NAMING_SERVICE 1

// Choose between IORTABLE and NAMING_SERVICE methods to
// activate an object.
#define RESOLVE_WITH    IORTABLE
//#define RESOLVE_WITH    NAMING_SERVICE

// Use the relevant namespace
using namespace RELATEDINTERFACE_ns;
//******************************************************************************


XyzAppLayer::XyzAppLayer()
{
}


bool XyzAppLayer::run()
{
    //**************************************************************************
    // Add these lines to activate an object and run a server...                // <--

    // Declare the object to be activated.
    related_object_i obj_impl;

    // Activate the object according to the selected access method.

    // Define the object ID in Active Object Table
    #define OBJ_ID_AOT  "xyz_in_AOT"

    // Define the object ID reference                                           // <--
    #define OBJ_ID_REF  "obj_impl_ref_name"

    std::string strSrc;
    try
    {
        #if RESOLVE_WITH == IORTABLE
            strSrc = "IORTable";
            tao_layer_->register_with_ior_table<
        #else
            strSrc = "Naming Service";
            tao_layer_->register_with_naming_service<
        #endif
                                Related_object_i,
                                Relatedinterface>
                            (
                                &obj_impl,
                                OBJ_ID_AOT,
                                OBJ_ID_REF
                            );
    }
    catch(...)
    {
        ACE_DEBUG((LM_ERROR,
                    "failed to register with %s\n",
                    strSrc.c_str()));
        return false;
    }


    ACE_DEBUG((LM_INFO, "%T - %s server started, waiting for requests...\n\n", __FILE__));
    try
    {
        tao_layer_->orb()->run();
    }
    catch(...)
    {
        ACE_DEBUG((LM_ERROR, "orb exception."));
        return false;
    }

    return true;
}


