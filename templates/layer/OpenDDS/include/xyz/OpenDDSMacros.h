#pragma once

#define OPENDDS_REGISTER_TYPE_SUPPORT(topic_namespace, topic_type)\
    topic_namespace::topic_type##TypeSupport_var ts_##topic_type =\
    new topic_namespace::topic_type##TypeSupportImpl;\
\
    if (ts_##topic_type->register_type(this->domain_participant_, "") != DDS::RETCODE_OK)\
    {\
        ACE_ERROR_RETURN((LM_ERROR,\
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")\
                            ACE_TEXT(" register_type failed!\n")),\
                            false);\
    }


#define OPENDDS_CREATE_TOPIC(topic_type, topic_name)\
    ::DDS::Topic_var topic_##topic_name = this->domain_participant_->create_topic(\
                                        #topic_name,\
                                        ts_##topic_type->get_type_name(),\
                                        TOPIC_QOS_DEFAULT,\
                                        0,\
                                        OpenDDS::DCPS::DEFAULT_STATUS_MASK);\
\
    if (!topic_##topic_name)\
    {\
        ACE_ERROR_RETURN((LM_ERROR,\
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")\
                            ACE_TEXT(" create_topic failed!\n")),\
                            false);\
    }


#define OPENDDS_CREATE_WRITER(topic_namespace, topic_type, topic_name, writer_name)\
    DDS::DataWriter_var writer_##writer_name =\
        publisher->create_datawriter(topic_##topic_name,\
                                    DATAWRITER_QOS_DEFAULT,\
                                    0,\
                                    OpenDDS::DCPS::DEFAULT_STATUS_MASK);\
\
    if (!writer_##writer_name)\
    {\
        ACE_ERROR_RETURN((LM_ERROR,\
                            ACE_TEXT("ERROR: %N:%l: init_DDS() -")\
                            ACE_TEXT(" create_datawriter failed!\n")),\
                            false);\
    }\
\
    topic_name##_writer_ =\
        topic_namespace::##topic_type##DataWriter::_narrow(writer_##writer_name);\
\
    if (!topic_name##_writer_)\
    {\
        ACE_ERROR_RETURN((LM_ERROR,\
                            ACE_TEXT("ERROR: %N:%l: main() -")\
                            ACE_TEXT(" _narrow failed!\n")),\
                            false);\
    }


#define OPENDDS_CREATE_READER(topic_namespace, topic_type, topic_name, listenner_name, reader_name)\
    DDS::DataReaderListener_var listener##listenner_name (\
        new Listenner<CLIENT,\
                        topic_namespace::topic_type##DataReader,\
                        topic_namespace::topic_type##DataReader_var,\
                        topic_namespace::topic_type>(this->client_));\
\
    DDS::DataReader_var reader##reader_name =\
        subscriber->create_datareader(topic_##topic_name,\
                                        DATAREADER_QOS_DEFAULT,\
                                        listener##listenner_name,\
                                        OpenDDS::DCPS::DEFAULT_STATUS_MASK);\
\
    if (!reader##reader_name)\
    {\
        ACE_ERROR_RETURN((LM_ERROR,\
                            ACE_TEXT("ERROR: %N:%l: main() -")\
                            ACE_TEXT(" create_datareader failed!\n")),\
                            false);\
    }

#define OPENDDS_DECLARE_WRITER_MEMBER(topic_namespace, topic_type, topic_name)\
    topic_namespace::##topic_type##DataWriter_var topic_name##_writer_;

#define OPENDDS_WRITE(topic_name, topic)\
    topic_name##_writer_->write(topic, this->handle_);
