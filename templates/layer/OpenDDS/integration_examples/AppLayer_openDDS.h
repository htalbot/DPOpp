
// Include DDS layer header.                                                    // <--
#include "xyz/xyzOpenDDSLayer.h"

class XyzAppLayer
{
public:

    XyzAppLayer();

    virtual unsigned long opendds_termination_timeout_ms();                     // <--
    virtual unsigned long opendds_shutdown_timeout_ms();                        // <--

    // Set DDS layer                                                            // <--
    void dds_layer(XyzOpenDDSLayer<XyzAppLayer> * dds_layer)
    {
        dds_layer_ = dds_layer;
    }

    // Get DDS layer                                                            // <--
    XyzOpenDDSLayer<XyzAppLayer> * dds_layer()
    {
        return dds_layer_;
    }

    #ifdef AS_SUBSCRIBER
        void receive_topic(const TOPIC_NAMESPACE::related_topic_obj &);
    #endif

    #ifdef AS_PUBLISHER
        bool generate_topic();
    #endif

protected:

    // Keep a reference on DDS layer                                            // <--
    XyzOpenDDSLayer<XyzAppLayer> * dds_layer_;
};

