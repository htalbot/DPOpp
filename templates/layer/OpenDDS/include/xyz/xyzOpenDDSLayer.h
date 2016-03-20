#ifndef XYZ_OPENDDSLAYER_H
#define XYZ_OPENDDSLAYER_H

//#define AS_PUBLISHER
//#define AS_SUBSCRIBER

#include "related_topic_host/related_topic_hostC.h"
#include "related_topic_host/related_topic_hostTypeSupportImpl.h"

#include "xyz/xyzOpenDDSLayerBase.h"

#ifdef AS_SUBSCRIBER
#   include "xyz/xyzOpenDDSListener.h"
#endif

#include "xyz/OpenDDSMacros.h"

template<class CLIENT>
class XyzOpenDDSLayer: public XyzOpenDDSLayerBase<CLIENT>
{
public:
    #ifdef AS_PUBLISHER
        bool send_topic(const TOPIC_NAMESPACE::related_topic_obj &);
    #endif

protected:

    #ifdef AS_PUBLISHER
        // OPENDDS_DECLARE_WRITER_MEMBER(topic namespace, topic_type, topic_name);
        OPENDDS_DECLARE_WRITER_MEMBER(TOPIC_NAMESPACE, related_topic_obj, <topic_name>);                            // <--
    #endif

    virtual bool prepare(
        ::DDS::Publisher_var &,
        ::DDS::Subscriber_var &);
};

template<class CLIENT>
bool XyzOpenDDSLayer<CLIENT>::prepare(
    ::DDS::Publisher_var & publisher,
    ::DDS::Subscriber_var & subscriber)
{
    // OPENDDS_REGISTER_TYPE_SUPPORT(topic namespace, topic_type)
    OPENDDS_REGISTER_TYPE_SUPPORT(TOPIC_NAMESPACE, related_topic_obj)

    // OPENDDS_CREATE_TOPIC(topic_type, topic_name)
    OPENDDS_CREATE_TOPIC(related_topic_obj, <topic_name>)                                                           // <--

    #ifdef AS_PUBLISHER
        // OPENDDS_CREATE_WRITER(topic namespace, topic_type, topic_name, writer_name)
        OPENDDS_CREATE_WRITER(TOPIC_NAMESPACE, related_topic_obj, <topic_name>, <writer_name>)                      // <--
    #endif

    #ifdef AS_SUBSCRIBER
        // OPENDDS_CREATE_READER(topic namespace, topic_type, topic_name, listenner_name, reader_name)
        OPENDDS_CREATE_READER(TOPIC_NAMESPACE, related_topic_obj, <topic_name>, <listenner_name>, <reader_name>)    // <--
    #endif

    return true;
}


#ifdef AS_PUBLISHER
    template<class CLIENT>
    bool XyzOpenDDSLayer<CLIENT>::send_topic(
            const TOPIC_NAMESPACE::related_topic_obj & topic)
    {
        try
        {
            // Have the writer publish the topic
            DDS::ReturnCode_t result = OPENDDS_WRITE(<topic_name>, topic);                                          // <--
            return (result == DDS::RETCODE_OK);
        }
        catch(...)
        {
            ACE_DEBUG((LM_ERROR, "DDS write (TOPIC_NAMESPACE::related_topic_obj) exception."));
            return false;
        }
    }
#endif // AS_PUBLISHER


#endif // XYZ_OPENDDSLAYER_H

