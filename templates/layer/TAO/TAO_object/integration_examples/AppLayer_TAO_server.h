
// Include TAO layer header.                                                    // <--
#include "test_xyzTAOLayer.h"

class Test_xyzAppLayer
{
public:

    Test_xyzAppLayer();

    // Set tao layer                                                            // <--
    void tao_layer(Test_xyzTAOLayer * layer)
    {
        tao_layer_ = layer;
    }

protected:

    // Keep a reference on TAO layer.                                           // <--
    Test_xyzTAOLayer * tao_layer_;
};
