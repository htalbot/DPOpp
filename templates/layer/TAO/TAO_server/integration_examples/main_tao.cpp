
// Include the application layer header.
#include "xyzAppLayer.h"

int main(int argc, char * argv[])
{
    XyzAppLayer app_layer;

    {
        // For app_layer having objects, it's important that
        // tao_layer's destructor is called before app_layer's one.
        // Otherwise, app_layer's destructor deletes the objects and
        // tao_layer crashes when deactivating these objects.

        // Declare TAO layer.
        XyzTAOLayer tao_layer;

        // Initialize TAO layer.
        if (tao_layer.init(argc, argv))
        {
            // Set app_layer's tao_layer
            app_layer.tao_layer(&tao_layer);

            try
            {
                // Run the application.
                if (!app_layer.run())
                {
                    ACE_DEBUG((LM_ERROR, "\nApplication layer returned false.\n"));
                }
            }
            catch(...)
            {
                ACE_DEBUG((LM_ERROR, "\nException while running "
                                        "Application layer\n"));
            }
        }
    }

    return 0;
}
