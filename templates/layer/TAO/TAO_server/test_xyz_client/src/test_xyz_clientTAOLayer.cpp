#include "test_xyz_clientTAOLayer.h"
#include "ace/INET_Addr.h"

Test_xyz_clientTAOLayer::Test_xyz_clientTAOLayer()
: ctrl_end_(0)
, init_(false)
, connection_timeout_orb_ms_(1000)
, request_timeout_orb_ms_(1000)
, request_timeout_thread_ms_(1000)
, taolayer_retry_loop_timeout_ms_(1000)
, taolayer_retry_attempts_(3)
{
}


Test_xyz_clientTAOLayer::~Test_xyz_clientTAOLayer()
{
    if (ctrl_end_)
    {
        ctrl_end_->wait();
        delete ctrl_end_;
    }
}


bool Test_xyz_clientTAOLayer::init(
    int argc,
    ACE_TCHAR *argv[],
    const char *orb_name)
{
    if (init_)
    {
        return true;
    }

    ctrl_end_ = new CtrlEnd(this);

#if AS_TAO_SERVER == 1
    try
    {
        if (orb_manager_.init_child_poa (argc, argv, "child_poa", orb_name) == -1)
        {
            ACE_DEBUG((LM_ERROR, "Can't init child poa.\n"));
            return false;
        }
    }
    catch(...)
    {
        ACE_DEBUG((LM_ERROR, "Exception while initializing child poa.\n"));
        return false;
    }

    // activate poa_manager
    orb_manager_.activate_poa_manager();
#else
    #if AS_TAO_CLIENT == 1
        if (orb_manager_.init(argc, argv, orb_name) == -1)
        {
            ACE_DEBUG((LM_ERROR, "Can't init orb manager.\n"));
            return false;
        }
    #endif
#endif

    if (CORBA::is_nil(orb()))
    {
        ACE_DEBUG((LM_ERROR, "Initialization of orb manager returned nil.\n"));
        return false;
    }

    init_QOS();

    init_ = true;

    return true;
}

void Test_xyz_clientTAOLayer::init_QOS()
{
    CORBA::Object_var object = orb()->resolve_initial_references("ORBPolicyManager");
    policy_manager_ = CORBA::PolicyManager::_narrow(object.in());

    object = orb()->resolve_initial_references("PolicyCurrent");
    policy_current_ = CORBA::PolicyCurrent::_narrow(object.in());

    // Disable all default policies.
    CORBA::PolicyList policies;
    policies.length(0);
    policy_manager_->set_policy_overrides(policies, CORBA::SET_OVERRIDE);
    policy_current_->set_policy_overrides(policies, CORBA::SET_OVERRIDE);
}

CORBA::ORB_var Test_xyz_clientTAOLayer::orb()
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_);
    return orb_manager_.orb();
}


void Test_xyz_clientTAOLayer::shutdown()
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_);

    // Here, If we shutdown synchronously, the caller may lose
    // the connection with the object and not get
    // the response. That's why we shutdown asynchronously.
    if (ctrl_end_)
    {
        ctrl_end_->activate();
    }
}


void Test_xyz_clientTAOLayer::set_connection_timeout_orb(
    int timeout_ms)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
    if (!guard.locked())
    {
        ACE_DEBUG((LM_ERROR, "Acquiring shutting_down_mutex_ failed.\n"));
        return;
    }

    // This method has effect on remote connection (server host different from client host)
    connection_timeout_orb_ms_ = timeout_ms;

    // TimeT has 100 nanosecond resolution.
    int usec(10); // ==> usec
    int msec(1000); // ==> msec
    int timeout_ns = usec * msec * timeout_ms;

    TimeBase::TimeT relative_rt_timeout = timeout_ns;
    CORBA::Any relative_rt_timeout_as_any;
    relative_rt_timeout_as_any <<= relative_rt_timeout;

    CORBA::PolicyList policies;
    policies.length(1);
    policies[0] = orb()->create_policy (TAO::CONNECTION_TIMEOUT_POLICY_TYPE, relative_rt_timeout_as_any);

    policy_manager_->set_policy_overrides (policies, CORBA::SET_OVERRIDE);

    // Cleanup.
    policies[0]->destroy ();
}

void Test_xyz_clientTAOLayer::get_connection_timeout_orb(
    int & timeout_ms)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_);
    timeout_ms = connection_timeout_orb_ms_;
}

void Test_xyz_clientTAOLayer::set_request_timeout_orb(
    int timeout_ms)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
    if (!guard.locked())
    {
        ACE_DEBUG((LM_ERROR, "Acquiring shutting_down_mutex_ failed.\n"));
        return;
    }

    request_timeout_orb_ms_ = timeout_ms;

    // TimeT has 100 nanosecond resolution.
    int usec(10); // ==> usec
    int msec(1000); // ==> msec
    int timeout_ns = usec * msec * timeout_ms;

    TimeBase::TimeT relative_rt_timeout = timeout_ns;
    CORBA::Any relative_rt_timeout_as_any;
    relative_rt_timeout_as_any <<= relative_rt_timeout;

    // Create the policy and put it in a policy list.
    CORBA::PolicyList policies;
    policies.length(1);
    policies[0] = orb()->create_policy(Messaging::RELATIVE_RT_TIMEOUT_POLICY_TYPE, relative_rt_timeout_as_any);

    // Apply the policy at the ORB level using the ORBPolicyManager.
    policy_manager_->set_policy_overrides(policies, CORBA::SET_OVERRIDE);

    // Cleanup.
    policies[0]->destroy ();
}

void Test_xyz_clientTAOLayer::get_request_timeout_orb(
    int & timeout_ms)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_);
    timeout_ms = request_timeout_orb_ms_;
}

void Test_xyz_clientTAOLayer::set_request_timeout_thread(
    int timeout_ms)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(shutting_down_mutex_, 0);
    if (!guard.locked())
    {
        ACE_DEBUG((LM_ERROR, "Acquiring shutting_down_mutex_ failed.\n"));
        return;
    }

    request_timeout_thread_ms_ = timeout_ms;

    // TimeT has 100 nanosecond resolution.
    int usec(10); // ==> usec
    int msec(1000); // ==> msec
    int timeout_ns = usec * msec * timeout_ms;

    TimeBase::TimeT relative_rt_timeout = timeout_ns;
    CORBA::Any relative_rt_timeout_as_any;
    relative_rt_timeout_as_any <<= relative_rt_timeout;

    // Create the policy and put it in a policy list.
    CORBA::PolicyList policies;
    policies.length(1);
    policies[0] = orb()->create_policy(Messaging::RELATIVE_RT_TIMEOUT_POLICY_TYPE, relative_rt_timeout_as_any);

    // Apply the policy at the ORB level using the ORBPolicyManager.
    policy_current_->set_policy_overrides(policies, CORBA::SET_OVERRIDE);

    // Cleanup.
    policies[0]->destroy ();
}

bool Test_xyz_clientTAOLayer::set_taolayer_retry_params(
    int loop_timeout_ms,
    int attempts,
    bool /*raise_event*/)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(set_tao_layer_params_mutex_);

    // For global object timeout management

    taolayer_retry_loop_timeout_ms_ = loop_timeout_ms;
    taolayer_retry_attempts_ = attempts;

    return true;
}

void Test_xyz_clientTAOLayer::get_taolayer_retry_params(
    int & loop_timeout_ms,
    int & attempts)
{
    ACE_Guard<ACE_Recursive_Thread_Mutex> guard(set_tao_layer_params_mutex_);

    loop_timeout_ms = taolayer_retry_loop_timeout_ms_;
    attempts = taolayer_retry_attempts_;
}

void Test_xyz_clientTAOLayer::unregister_objects()
{
    if (init_)
    {
        // unbind from naming service
        CosNaming::NamingContext_var nc;

        if (vect_ref_name_ns_.size() != 0)
        {
            nc = resolve_init<CosNaming::NamingContext>(orb().in(), "NameService");
        }

        std::vector<std::string>::iterator it_ns;
        for (it_ns = vect_ref_name_ns_.begin(); it_ns != vect_ref_name_ns_.end(); it_ns++)
        {
            CosNaming::Name object_ref_name(1);
            object_ref_name.length (1);
            object_ref_name[0].id = CORBA::string_dup(it_ns->c_str());
            nc->unbind(object_ref_name);
        }

        vect_ref_name_ns_.clear();


        // unbind from iortable
        IORTable::Table_var ior_table;
        if (vect_ref_name_iortable_.size() != 0)
        {
            ior_table = resolve_init<IORTable::Table>(orb().in(), "IORTable");
        }

        std::vector<std::string>::iterator it_ior;
        for (it_ior = vect_ref_name_iortable_.begin(); it_ior != vect_ref_name_iortable_.end(); it_ior++)
        {
            ior_table->unbind(it_ior->c_str());
        }

        vect_ref_name_iortable_.clear();
    }
}

void Test_xyz_clientTAOLayer::shutdown_i()
{
   if (init_)
   {
       unregister_objects();

       orb()->shutdown();

       init_ = false;
   }
}
