
#ifndef XYZ_TEST_XYZ_CLIENT_APPLAYER_H_
#define XYZ_TEST_XYZ_CLIENT_APPLAYER_H_

// Include TAO layer header.
#include "test_xyz_clientTAOLayer.h"

class Test_xyz_clientAppLayer
{
public:

    Test_xyz_clientAppLayer();

    void tao_layer(Test_xyz_clientTAOLayer * layer)
    {
        tao_layer_ = layer;
    }

    bool run();

protected:

    // Keep a reference on TAO layer.
    Test_xyz_clientTAOLayer * tao_layer_;
};

#endif // XYZ_TEST_XYZ_CLIENT_APPLAYER_H_
