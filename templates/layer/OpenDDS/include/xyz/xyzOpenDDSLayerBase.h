#ifndef XYZOPENDDSLAYERBASE_H
#define XYZOPENDDSLAYERBASE_H

#if !defined(AS_PUBLISHER) && !defined(AS_SUBSCRIBER)
#error AS_PUBLISHER or AS_SUBSCRIBER (or both) has to be defined
#endif


//  Windows only supports timed process mutexes and not
//  timed thread mutexes, use ACE_Process_Mutex.
#   include "ace/Process_Mutex.h"

#   include "dds/DdsDcpsInfoUtilsC.h"
#   include <dds/DCPS/Service_Participant.h>

#   ifdef AS_PUBLISHER
#       include <dds/DCPS/PublisherImpl.h>
#   endif
#   ifdef AS_SUBSCRIBER
#       include <dds/DCPS/SubscriberImpl.h>
#   endif // AS_SUBSCRIBER

#   include <dds/DCPS/Marked_Default_Qos.h>

#ifdef ACE_WIN32
#pragma warning(disable: 4251)
#   include <dds/DCPS/DomainParticipantImpl.h>
#   include <dds/DCPS/BuiltInTopicUtils.h>
#pragma warning(default: 4251)
#endif

// Bridges the DDS and the client that is using DDS.
template<class CLIENT>
class XyzOpenDDSLayerBase: public ACE_Task_Base
{
public:

    XyzOpenDDSLayerBase();
    virtual ~XyzOpenDDSLayerBase();
    virtual bool init_DDS(
        int argc, ACE_TCHAR *argv[],
        CLIENT * client,
        int domain);
    virtual void shutdown_DDS();
    virtual bool termination_ok();

protected:

    int svc();
    bool wait_for_termination();

    // Abstract virtual methods
    virtual bool prepare(
        ::DDS::Publisher_var &,
        ::DDS::Subscriber_var &) = 0;

protected:

    CLIENT * client_;
    ACE_Time_Value begin_;  // Because OpenDDS takes time to connect,
                            // we guard against premature shutdown of DDS.
    bool shutdown_;
    ACE_Atomic_Op<ACE_Thread_Mutex,bool> shutting_down_;
    ACE_Process_Mutex svc_mutex_;
    bool termination_ok_;

    ::DDS::DomainParticipantFactory_var dpf_;
    ::DDS::DomainParticipant_var domain_participant_;

#   ifdef AS_PUBLISHER
    // Instance handle for publishing (one per key published)
    ::DDS::InstanceHandle_t handle_;
#   endif

#   ifdef AS_SUBSCRIBER
    // Nothing special for subscriber
#   endif
};


// Implementation

template<class CLIENT>
XyzOpenDDSLayerBase<CLIENT>::XyzOpenDDSLayerBase()
: client_(0)
, shutdown_(false)
, shutting_down_(false)
, termination_ok_(false)
#ifdef AS_PUBLISHER
, handle_(0)   // for publisher
#endif // AS_PUBLISHER
{
}

template<class CLIENT>
XyzOpenDDSLayerBase<CLIENT>::~XyzOpenDDSLayerBase()
{
    shutdown_DDS();
}

template<class CLIENT>
bool XyzOpenDDSLayerBase<CLIENT>::init_DDS(
    int argc, ACE_TCHAR *argv[],
    CLIENT * client,
    int domain)
{
    client_ = client;

    // Initialize the Service Participant
    OpenDDS::DCPS::Service_Participant * service_participant =
                                                        TheServiceParticipant;

    // Get participant factory
    dpf_ = service_participant->get_domain_participant_factory(argc, argv);
    if (!dpf_)
    {
        ACE_ERROR_RETURN((LM_ERROR,
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")
                            ACE_TEXT(" get_domain_participant_factory "
                                        "failed!\n")),
                            false);
    }


    // Create participant
    domain_participant_ = dpf_->create_participant(domain,
                                    PARTICIPANT_QOS_DEFAULT,
                                    0,
                                    ::OpenDDS::DCPS::DEFAULT_STATUS_MASK);
    if (!domain_participant_)
    {
        ACE_ERROR_RETURN((LM_ERROR,
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")
                            ACE_TEXT(" create_participant failed!\n")),
                            false);
    }

    ::DDS::Publisher_var publisher;

#   ifdef AS_PUBLISHER
    // Create Publisher
    publisher = domain_participant_->create_publisher(PUBLISHER_QOS_DEFAULT,
                                                        0,
                                                        OpenDDS::DCPS::DEFAULT_STATUS_MASK);

    if (!publisher)
    {
        ACE_ERROR_RETURN((LM_ERROR,
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")
                            ACE_TEXT(" create_publisher failed!\n")),
                            false);
    }
#   endif // AS_PUBLISHER


    DDS::Subscriber_var subscriber;

#   ifdef AS_SUBSCRIBER
    // Create Subscriber
    subscriber =
      domain_participant_->create_subscriber(SUBSCRIBER_QOS_DEFAULT,
                                                0,
                                                OpenDDS::DCPS::DEFAULT_STATUS_MASK);

    if (!subscriber)
    {
        ACE_ERROR_RETURN((LM_ERROR,
                            ACE_TEXT("ERROR: %N:%l: main() -")
                            ACE_TEXT(" create_subscriber failed!\n")),
                            false);
    }
#   endif // AS_SUBSCRIBER


    if (!prepare(publisher, subscriber))
    {
        return false;
    }

    begin_ = ACE_OS::gettimeofday();

    return true;
}

template<class CLIENT>
void XyzOpenDDSLayerBase<CLIENT>::shutdown_DDS()
{
    if (shutdown_)
    {
        return;
    }

    // Even if the shutdown is not actually done, let the process end
    // and don't let destructor (if it's not the first caller of
    // shutdown_DDS) calling shutdown_DDS again.
    shutdown_ = true;

    activate();

    if (!wait_for_termination())
    {
        ACE_DEBUG((LM_DEBUG, "%T - OpenDDS shutdown too long.\n"));
    }
}

template<class CLIENT>
bool XyzOpenDDSLayerBase<CLIENT>::termination_ok()
{
    return termination_ok_;
}

template<class CLIENT>
int XyzOpenDDSLayerBase<CLIENT>::svc()
{
    ACE_Guard<ACE_Process_Mutex> g(svc_mutex_);

    shutting_down_ = true;

    // Because OpenDDS takes time to connect,
    // we guard against premature shutdown of DDS.
    while (true)
    {
        if ((ACE_OS::gettimeofday() - begin_).get_msec() > client_->opendds_termination_timeout_ms())
        {
            ACE_OS::sleep(ACE_Time_Value(0, 10000)); // 10 ms
            break;
        }
    }

    try
    {
        // Clean up all the entities in the participant
        if (!CORBA::is_nil (domain_participant_.in ()) )
        {
            ACE_DEBUG((LM_DEBUG, "%T - delete_contained_entities...\n"));
            domain_participant_->delete_contained_entities ();

            // Clean up the participant
            ACE_DEBUG((LM_DEBUG, "%T - delete_participant ...\n"));
            dpf_->delete_participant (domain_participant_.in ());
        }

        // Clean up DDS
        ACE_DEBUG((LM_DEBUG, "%T - TheServiceParticipant->shutdown...\n"));
        TheServiceParticipant->shutdown ();

        termination_ok_ = true;
    }
    catch(...)
    {
        ACE_DEBUG((LM_DEBUG, "%T - exception.\n"));
    }

    return 0;
}

template<class CLIENT>
bool XyzOpenDDSLayerBase<CLIENT>::wait_for_termination()
{
    while (!shutting_down_.value())
    {
        ACE_OS::sleep(ACE_Time_Value(0, 10000));
    }

    ACE_Time_Value waiting_time_after_termination_timeout_tv(0, client_->opendds_shutdown_timeout_ms() * 1000);
    ACE_Time_Value termination_timeout_tv(0, client_->opendds_termination_timeout_ms() * 1000);
    ACE_Time_Value wait = ACE_OS::gettimeofday();
    if ((wait - begin_).get_msec() <= client_->opendds_termination_timeout_ms())
    {
        ACE_Time_Value diff_tv = (begin_ + termination_timeout_tv + waiting_time_after_termination_timeout_tv) - wait;
        wait.sec(wait.sec() + diff_tv.sec());
    }
    else
    {
        wait.sec(wait.sec() + waiting_time_after_termination_timeout_tv.sec());
    }

    bool rc = true;
    if (svc_mutex_.acquire(wait) == -1) rc = false;
    svc_mutex_.release();

    ACE_DEBUG((LM_DEBUG, "%T - wait terminated: %s\n", rc ? "gracefully" : "by timeout"));

    return rc;
}

#endif // XYZOPENDDSLAYERBASE_H



