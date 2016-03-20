// Include the application layer header.
#include "xyzAppLayer.h"

int ACE_TMAIN (int argc, char *argv[])
{
    // Declare DDS layer.                                                       // <--
    XyzOpenDDSLayer<XyzAppLayer> dds_layer;

    // Declare application layer object.
    XyzAppLayer app_layer;

    // Set the domain ID                                                        // <--
    int domain_id(11);

    // Initialize DDS layer.                                                    // <--
    if ( dds_layer.init_DDS(argc, argv,
                            &app_layer,
                            domain_id) )
    {
        app_layer.dds_layer(&dds_layer);
        app_layer.run();
    }
    else
    {
        ACE_ERROR((LM_ERROR, ACE_TEXT("ERROR: Initialization of "
                                        "DDS failed!\n")));
    }

    return 0;
}
