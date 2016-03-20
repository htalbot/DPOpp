
#include "test_xyz_serverAppLayer.h"

int main(int argc, char * argv[])
{
   Test_xyz_serverAppLayer app_layer;

    {
        // For app_layer having objects, it's important that
        // tao_layer's destructor is called before app_layer's one.
        // Otherwise, app_layer's destructor deletes the objects and
        // tao_layer crashes when deactivating these objects.

        // Declare TAO layer.
        Test_xyz_serverTAOLayer tao_layer;

        // Initialize tao_layer
        if (tao_layer.init(argc, argv))
        {
            // Set tao_layer to app_layer.
            app_layer.tao_layer(&tao_layer);

            try
            {
                // Run app_layer.
                if (!app_layer.run())
                {
                    ACE_DEBUG((LM_ERROR, "Test_xyz_serverApplayer return false.\n"));
                }
            }
            catch(...)
            {
                ACE_DEBUG((LM_ERROR, "failed to get ref on object\n"));
            }
        }
    }

    return 0;
}
