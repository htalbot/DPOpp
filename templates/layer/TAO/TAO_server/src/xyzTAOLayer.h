#ifndef XYZ_TAOLAYER_H
#define XYZ_TAOLAYER_H

#include "ace/Task.h"
#include <string>
#include <vector>

/** TO_CHANGE: uncomment depending on server and/or client use **/
#define AS_TAO_SERVER 1
//#define AS_TAO_CLIENT 1

#if !defined(AS_TAO_SERVER) && !defined(AS_TAO_CLIENT)
#error AS_TAO_SERVER or AS_TAO_CLIENT (or both) has to be defined
#endif

// Needed TAO headers
#include "tao/Utils/ORB_Manager.h"
#if AS_TAO_SERVER == 1
#include "orbsvcs/CosNamingS.h"
#endif
#if AS_TAO_CLIENT == 1
#include "orbsvcs/CosNamingC.h"
#endif
#include "TAO/tao/Messaging/Messaging.h"
#include "TAOLayerUtils.h"

#include "tao/Utils/ORB_Manager.h"
#include "tao/IORTable/IORTable.h"

class CtrlEnd;

/**
 * @class Test_xyzTAOLayer
 *
 * @brief Bridges the TAO and Application Layer functionality.
 *
 */
class XyzTAOLayer
{
    class CtrlEnd: public ACE_Task_Base
    {
    public:
        CtrlEnd(XyzTAOLayer * tao_layer)
        : tao_layer_(tao_layer)
        {
        }

        virtual int svc()
        {
            // Let the caller get the response.
            ACE_Time_Value tv(0, 800000);
            ACE_OS::sleep(tv);

            // Shutdown.
            tao_layer_->shutdown_i();

            return 0;
        }

    protected:
        XyzTAOLayer * tao_layer_;
    };

public:

    XyzTAOLayer();

    virtual ~XyzTAOLayer();

    virtual bool init(
        int argc,
        ACE_TCHAR *argv[],
        const char *orb_name = 0);

    virtual CORBA::ORB_var orb();
    virtual void shutdown();

    virtual void set_connection_timeout_orb(
        int timeout_ms);
    virtual void set_request_timeout_orb(
        int timeout_ms);
    virtual void set_request_timeout_thread(
        int timeout_ms);

    virtual void get_connection_timeout_orb(
        int & connection_timeout_orb_ms);
    virtual void get_request_timeout_orb(
        int & timeout_ms);

    virtual bool set_taolayer_retry_params(
        int loop_timeout_ms,
        int attempts,
        bool raise_event = true);
    virtual void get_taolayer_retry_params(
        int & loop_timeout_ms,
        int & attempts);

    template <typename Interface>
    typename Interface::_ptr_type timed_object(
        typename Interface::_ptr_type obj,
        long timeout_ms)
    {
        ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
        if (!guard.locked())
        {
            typename Interface::_var_type ref;
            return ref._retn();
        }

        int usec(10); // ==> usec
        int msec(1000); // ==> msec
        int timeout_ns = usec * msec * timeout_ms;

        TimeBase::TimeT relative_rt_timeout = timeout_ns;
        CORBA::Any relative_rt_timeout_as_any;
        relative_rt_timeout_as_any <<= relative_rt_timeout;

        // Create the policy and put it in a policy list.
        CORBA::PolicyList policies;
        policies.length(1);

        // Override the object policies.
        policies[0] = orb()->create_policy(Messaging::RELATIVE_RT_TIMEOUT_POLICY_TYPE, relative_rt_timeout_as_any);

        // Create a new object reference!
        CORBA::Object_var object = obj->_set_policy_overrides(policies, CORBA::SET_OVERRIDE);
        typename Interface::_var_type ref = Interface::_narrow(object.in());

        // Cleanup.
        policies[0]->destroy();

        return ref._retn();
    }

    template <typename Interface>
    typename Interface::_ptr_type get_ref_from_ns(
        const char * szName)
    {
        ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
        if (!guard.locked())
        {
            typename Interface::_var_type ref;
            return ref._retn();
        }

        CosNaming::Name object_name(1);
        object_name.length (1);
        object_name[0].id = CORBA::string_dup (szName);

        std::string service_id("NameService");
        for (int i = 0; i != taolayer_retry_attempts_; i++)
        {
            try
            {
                // get a ref on naming service
                CosNaming::NamingContext_var nc = resolve_init<CosNaming::NamingContext>(
                                                            orb_manager_.orb(),
                                                            service_id.c_str());

                // resolve name and get object ref
                CORBA::Object_var obj = resolve_name<Interface>(nc.in(), object_name);
                typename Interface::_var_type ref = Interface::_narrow(obj.in());
                if (CORBA::is_nil(ref.ptr()))
                {
                    ACE_OS::sleep(ACE_Time_Value(0, taolayer_retry_loop_timeout_ms_ * 1000));
                }
                else
                {
                    return ref._retn();
                }
            }
            catch(...)
            {
                ACE_OS::sleep(ACE_Time_Value(0, taolayer_retry_loop_timeout_ms_ * 1000));
            }
        }

        return 0;
    }


    template <typename Interface>
    typename Interface::_ptr_type get_ref_from_iortable(
        const char * szName)
    {
        ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
        if (!guard.locked())
        {
            typename Interface::_var_type ref;
            return ref._retn();
        }

        for (int i = 0; i != taolayer_retry_attempts_; i++)
        {
            try
            {
                CORBA::Object_var obj = orb()->string_to_object(szName);
                typename Interface::_var_type ref = Interface::_narrow(obj.in());
                if (CORBA::is_nil(ref.in()))
                {
                    ACE_OS::sleep(ACE_Time_Value(0, taolayer_retry_loop_timeout_ms_ * 1000));
                }
                else
                {
                    return ref._retn();
                }
            }
            catch(...)
            {
                ACE_OS::sleep(ACE_Time_Value(0, taolayer_retry_loop_timeout_ms_ * 1000));
            }
        }

        return 0;
    }


    template <typename Object, typename Interface>
    bool register_with_naming_service(
        Object * obj,
        const char * szObjectID,
        const char * szRefName)
    {
        try
        {
            ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
            if (!guard.locked())
            {
                return false;
            }

            CORBA::ORB_var orb = this->orb_manager_.orb();

            // Activate object
            if (!this->orb_manager_.activate_under_child_poa(szObjectID, obj))
            {
                ACE_DEBUG((LM_ERROR, "Can't activate object under child poa: %s\n", szObjectID));
                return false;
            }

            // Register with naming service
            typename Interface::_var_type temp_ref = obj->_this();

            CosNaming::Name object_ref_name(1);
            object_ref_name.length (1);
            object_ref_name[0].id = CORBA::string_dup(szRefName);

            std::string service_id("NameService");
            try
            {
                // get a ref on naming service
                CosNaming::NamingContext_var nc = resolve_init<CosNaming::NamingContext>(
                                                                 orb.in(), service_id.c_str());

                //Register the object with Naming Service
                nc->rebind(object_ref_name, temp_ref.in());
            }
            catch(...)
            {
                ACE_DEBUG((LM_ERROR, "Can't resolve CosNaming::NamingContext.\n"));
                return false;
            }

            vect_ref_name_ns_.push_back(szRefName);
        }
        catch(...)
        {
            ACE_DEBUG((LM_ERROR, "register_with_naming_service exception: %s.\n", szRefName));
            return false;
        }

        return true;
    }


    template <typename Object, typename Interface>
    bool register_with_ior_table(
        Object * obj,
        const char * szObjectID,
        const char * szRefName)
    {
        try
        {
            ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
            if (!guard.locked())
            {
                return false;
            }

            CORBA::ORB_var orb = this->orb_manager_.orb();

            // Activate object
            this->orb_manager_.activate_under_child_poa(szObjectID, obj);

            // Register with IORTable
            typename Interface::_var_type temp_ref = obj->_this();
            CORBA::String_var ior_str = orb->object_to_string(temp_ref.in());

            CORBA::Object_var tobj = orb->resolve_initial_references("IORTable");
            IORTable::Table_var table = IORTable::Table::_narrow(tobj.in());
            table->rebind(szRefName, ior_str.in());

            vect_ref_name_iortable_.push_back(szRefName);
        }
        catch(...)
        {
            ACE_DEBUG((LM_ERROR, "register_with_ior_table exception: %s.\n", szRefName));
            return false;
        }

        return true;
    }

protected:

    void init_QOS();
    void unregister_objects();
    void shutdown_i();

    CORBA::PolicyManager_var policy_manager_;
    CORBA::PolicyCurrent_var policy_current_;

    CtrlEnd * ctrl_end_;

    TAO_ORB_Manager orb_manager_;

    std::vector<std::string> vect_ref_name_ns_;
    std::vector<std::string> vect_ref_name_iortable_;

    bool init_;
    int connection_timeout_orb_ms_;
    int request_timeout_orb_ms_;
    int request_timeout_thread_ms_;
    int taolayer_retry_loop_timeout_ms_;
    int taolayer_retry_attempts_;
    ACE_Recursive_Thread_Mutex shutting_down_mutex_;
    ACE_Recursive_Thread_Mutex set_tao_layer_params_mutex_;
};


#endif // XYZ_TAOLAYER_H
