
// Determine if stdio.h is relevant                                             // <--
#include <stdio.h>
#include <sstream>

XyzAppLayer::XyzAppLayer()
{
}


// Define OpenDDS termination timeout                                           // <--
unsigned long XyzAppLayer::opendds_termination_timeout_ms()
{
    return 10000; // Get it from...
}

// Define OpenDDS shutdown timeout                                              // <--
unsigned long XyzAppLayer::opendds_shutdown_timeout_ms()                        // <--
{
    return 20000; // Get it from...
}

#ifdef AS_SUBSCRIBER
// Define this method                                                           // <--
void XyzAppLayer::receive_topic(
                        const TOPIC_NAMESPACE::related_topic_obj & topic)
{
    std::ostringstream str_id;

    str_id << topic.id;

    printf("xyz_AppLayer::receive_topic - %s: %d\n",
            str_id.str().c_str(),
            topic.value);
}
#endif

#ifdef AS_PUBLISHER
// Define this method                                                           // <--
bool XyzAppLayer::generate_topic()
{
    bool generate_result = false;
    static int nValue(0);

    // Create the relatedTopic and set the fields.
    TOPIC_NAMESPACE::related_topic_obj topic;

    topic.id = CORBA::string_dup("NewID");
    topic.value = nValue++;

    // Publish the topic.
    if (0 != dds_layer_)
    {
        std::ostringstream str_id;
        str_id << topic.id;
        ACE_DEBUG((LM_DEBUG, "sending topic: %s - %d\n",
                    str_id.str().c_str(),
                    topic.value));

        generate_result = dds_layer_->send_topic(topic);
    }

    return generate_result;
}
#endif


// Update the run method.                                                       // <--
int XyzAppLayer::run()
{
    // ...

    #ifdef AS_PUBLISHER
    for (int i = 0; i < 600; ++i)
    {
        if ( ! generate_topic())
        {
            ACE_ERROR((LM_ERROR, ACE_TEXT("Error - failed to "
                                            "generate topic\n")));
        }
        ACE_OS::sleep(1);
    }
    #else
    ACE_DEBUG((LM_DEBUG, "Waiting...\n"));
    ACE_OS::sleep(600);
    #endif

    return 1;
}
