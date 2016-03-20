
// Include TAO layer header.                                                    // <--
#include "xyzTAOLayer.h"

class XyzAppLayer
{
public:

    XyzAppLayer();

    // Set tao layer                                                            // <--
    void tao_layer(XyzTAOLayer * layer)
    {
        tao_layer_ = layer;
    }

protected:

    // Keep a reference on TAO layer.                                           // <--
    XyzTAOLayer * tao_layer_;
};

