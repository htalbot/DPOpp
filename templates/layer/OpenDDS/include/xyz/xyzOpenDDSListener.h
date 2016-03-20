#ifndef XYZOPENDDSLISTENER_H_
#define XYZOPENDDSLISTENER_H_

#include <dds/DdsDcpsSubscriptionC.h>

template<class CLIENT, class READER, class READER_VAR, class TOPIC>
class Listenner
  : public virtual OpenDDS::DCPS::LocalObject<DDS::DataReaderListener>
{
public:

  Listenner(CLIENT *);

  virtual ~Listenner();

  virtual void on_requested_deadline_missed (
    ::DDS::DataReader_ptr reader,
    const ::DDS::RequestedDeadlineMissedStatus & status)
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_requested_incompatible_qos (
    ::DDS::DataReader_ptr reader,
    const ::DDS::RequestedIncompatibleQosStatus & status)
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_sample_rejected (
    ::DDS::DataReader_ptr reader,
    const ::DDS::SampleRejectedStatus & status
    )
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_liveliness_changed (
    ::DDS::DataReader_ptr reader,
    const ::DDS::LivelinessChangedStatus & status)
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_data_available (
    ::DDS::DataReader_ptr reader)
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_subscription_matched (
    ::DDS::DataReader_ptr reader,
    const ::DDS::SubscriptionMatchedStatus & status)
    ACE_THROW_SPEC ((::CORBA::SystemException));

  virtual void on_sample_lost (
    ::DDS::DataReader_ptr reader,
    const ::DDS::SampleLostStatus & status)
    ACE_THROW_SPEC ((::CORBA::SystemException));

private:

  // Pointer to the change monitor.  This class does not take ownership.
  CLIENT * client_;

};


// Implementattion

template<class CLIENT, class READER, class READER_VAR, class TOPIC>
Listenner<CLIENT, READER, READER_VAR, TOPIC>::Listenner(CLIENT * client)
: client_(client)
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
Listenner<CLIENT, READER, READER_VAR, TOPIC>::~Listenner()
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_data_available (::DDS::DataReader_ptr reader)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
   try
   {
        READER_VAR topic_dr = READER::_narrow(reader);
        if (CORBA::is_nil (topic_dr.in()))
        {
            ACE_ERROR((LM_ERROR, "Listenner::on_data_available()"
                        " _narrow failed.\n"));
            return;
        }

        TOPIC topic;
        DDS::SampleInfo si ;
        DDS::ReturnCode_t status = topic_dr->take_next_sample(topic, si);

        if (status == DDS::RETCODE_OK)
        {
            if (si.valid_data == 1)
            {
                if (0 != client_)
                {
                    client_->receive_topic(topic);
                }
                else
                {
                    ACE_DEBUG((LM_DEBUG, "Listenner::on_data_available()"
                                " no change_monitor_ defined\n"));
                }
            }
            else if (si.instance_state == DDS::NOT_ALIVE_DISPOSED_INSTANCE_STATE)
            {
                ACE_DEBUG((LM_DEBUG, "Instance is disposed\n"));
            }
            else if (si.instance_state == DDS::NOT_ALIVE_NO_WRITERS_INSTANCE_STATE)
            {
                ACE_DEBUG((LM_DEBUG, "Instance is unregistered\n"));
            }
            else
            {
                ACE_DEBUG((LM_DEBUG, "Received unknown instance state %d\n",
                            si.instance_state));
            }
        }
        else if (status == DDS::RETCODE_NO_DATA)
        {
            ACE_ERROR((LM_ERROR, "Listenner::on_data_available()"
                        " received DDS::RETCODE_NO_DATA!"));
        }
        else
        {
            ACE_ERROR((LM_ERROR, "Listenner::on_data_available()"
                        " read Message: Error: %d\n",
                        status));
        }
    }
    catch (CORBA::Exception&)
    {
        ACE_ERROR((LM_ERROR, "Listenner::on_data_available()"
                    " Exception caught in read\n"));
    }
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_requested_deadline_missed (
                                   ::DDS::DataReader_ptr,
                                   const ::DDS::RequestedDeadlineMissedStatus &)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_requested_incompatible_qos (
                                    ::DDS::DataReader_ptr,
                                    const ::DDS::RequestedIncompatibleQosStatus &)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_sample_rejected (
                         ::DDS::DataReader_ptr,
                         const ::DDS::SampleRejectedStatus &
                         )
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}



template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_liveliness_changed (
                            ::DDS::DataReader_ptr,
                            const ::DDS::LivelinessChangedStatus &)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_subscription_matched (
                            ::DDS::DataReader_ptr,
                            const ::DDS::SubscriptionMatchedStatus &)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}


template<class CLIENT, class READER, class READER_VAR, class TOPIC>
void Listenner<CLIENT, READER, READER_VAR, TOPIC>::on_sample_lost (
                     ::DDS::DataReader_ptr,
                     const ::DDS::SampleLostStatus &)
    ACE_THROW_SPEC ((::CORBA::SystemException))
{
}

#endif // XYZOPENDDSLISTENER_H_
