
// Include TAO layer header.                                                    // <--
#include "Test_xyzTAOLayer.h"

class Test_xyzAppLayer
{
public:

    Test_xyzAppLayer();

    // Set tao layer                                                            // <--
    void tao_layer(Test_xyzTAOLayer<Test_xyzAppLayer> * layer)
    {
        tao_layer_ = layer;
        if (0 != tao_layer_)
        {
            // Pass TAO layer to the client.
            tao_layer_->attach_client(this);
        }
    }

protected:

    // Keep a reference on TAO layer.                                           // <--
    Test_xyzTAOLayer<Test_xyzAppLayer> * tao_layer_;
};

