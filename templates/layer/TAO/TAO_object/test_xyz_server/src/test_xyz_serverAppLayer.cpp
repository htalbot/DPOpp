
#include "test_xyz_serverAppLayer.h"
#include "test_xyz_server/version.h"
#include "related_object_host/related_object_i.h"

#include <stdio.h>

#define IORTABLE 0
#define NAMING_SERVICE 1

// Choose between IORTABLE and NAMING_SERVICE methods to
// get reference on an object.
#define RESOLVE_WITH    IORTABLE
//#define RESOLVE_WITH    NAMING_SERVICE

// Namespace of interface
using namespace RELATEDINTERFACE_ns;


Test_xyz_serverAppLayer::Test_xyz_serverAppLayer()
{
}


bool Test_xyz_serverAppLayer::run()
{
    printf("Test_xyz_serverAppLayer - version: %d.%d.%d\n\n",
            TEST_XYZ_SERVER_MAJOR,
            TEST_XYZ_SERVER_MINOR,
            TEST_XYZ_SERVER_PATCH);

    // Define the object ID reference                                           // <--
    #define OBJ_ID_REF  "obj_impl_ref_name"

    std::string strSrc("No service");
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
                                &obj_impl_,
                                "Related_object_in_AOT",
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

