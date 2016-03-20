
#ifndef TAOLAYERUTILS_H
#define TAOLAYERUTILS_H

#include <iostream>
#include <assert.h>

template<class T>
typename T::_ptr_type
resolve_init(CORBA::ORB_ptr orb, const char * id)
{
    CORBA::Object_var obj;
    try {
        obj = orb->resolve_initial_references(id);
    }
    catch (const CORBA::ORB::InvalidName &) {
        throw;
    }
    catch (const CORBA::Exception & e) {
        std::cerr << "Cannot get initial reference for "
             << id << ": "
             << e
             << std::endl;
        throw 0;
    }
    assert(!CORBA::is_nil(obj.in()));

    typename T::_var_type ref;
    try {
        ref = T::_narrow(obj.in());
    }
    catch (const CORBA::Exception & e) {
        std::cerr << "Cannot narrow reference for "
             << id << ": "
             << e
             << std::endl;
        throw 0;
    }
    if (CORBA::is_nil(ref.in())) {
        std::cerr << "Incorrect type of reference for "
             << id << std::endl;
        throw 0;
    }
    return ref._retn();
}

//----------------------------------------------------------------

template<class T>
typename T::_ptr_type
resolve_name(
    CosNaming::NamingContext_ptr    nc,
    const CosNaming::Name &         name)
{
    CORBA::Object_var obj;
    try {
        obj = nc->resolve(name);
    }
    catch (const CosNaming::NamingContext::NotFound &) {
        throw;
    }
    catch (const CORBA::Exception & e) {
        std::cerr << "Cannot resolve binding: "
                  << e
                  << std::endl;
        throw 0;
    }
    if (CORBA::is_nil(obj.in())) {
        std::cerr << "Nil binding in Naming Service" << std::endl;
        throw 0;
    }

    typename T::_var_type ref;
    try {
        ref = T::_narrow(obj.in());
    }
    catch (const CORBA::Exception & e) {
        std::cerr << "Cannot narrow reference: "
                  << e
                  << std::endl;
        throw 0;
    }
    if (CORBA::is_nil(ref.in())) {
        std::cerr << "Reference has incorrect type" << std::endl;
        throw 0;
    }
    return ref._retn();
}


#endif // TAOLAYERUTILS_H
