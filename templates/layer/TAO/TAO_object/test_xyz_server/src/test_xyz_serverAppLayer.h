
#ifndef TEST_XYZ_SERVER_APPLAYER_H_
#define TEST_XYZ_SERVER_APPLAYER_H_

// Include TAO layer header.
#include "test_xyz_serverTAOLayer.h"
#include "xyz/related_object_i.h"

class Test_xyz_serverAppLayer
{
public:

    Test_xyz_serverAppLayer();

    void tao_layer(Test_xyz_serverTAOLayer * layer)
    {
        tao_layer_ = layer;
    }

    bool run();

protected:

    // Keep a reference on TAO layer.
    Test_xyz_serverTAOLayer * tao_layer_;

    Related_object_i obj_impl_;
};

#endif // TEST_XYZ_SERVER_APPLAYER_H_
