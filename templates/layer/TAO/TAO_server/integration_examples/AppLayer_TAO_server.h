
// Include TAO layer header.                                                    // <--
#include "xyzTAOLayer.h"

class XyzAppLayer
{
public:

    XyzAppLayer();

    // Method to keep reference on tao_layer and to attach                      // <--
    // client.
    void tao_layer(XyzTAOLayer * layer)
    {
        tao_layer_ = layer;
    }

protected:

    // Keep a reference on TAO layer.                                           // <--
    XyzTAOLayer * tao_layer_;
};
