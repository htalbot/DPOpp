#ifndef __PLUGIN_MACROS_H__
#define __PLUGIN_MACROS_H__

#include "ace/OS_Memory.h"

// DECLARE
#if defined (ACE_HAS_NEW_NOTHROW)
#   define PLUGIN_NEW_NOTHROW\
        void *operator new (size_t bytes, const ACE_nothrow_t&);
#   if !defined (ACE_LACKS_PLACEMENT_OPERATOR_DELETE)
#       define PLUGIN_DELETE_NOTHROW\
            void operator delete (void *p, const ACE_nothrow_t&) throw ();
#   endif /* ACE_LACKS_PLACEMENT_OPERATOR_DELETE */
#else
#   define PLUGIN_NEW_DELETE_NOTHROW
#endif

#define PLUGIN_MEM_DECLARE\
    void *operator new (size_t bytes);\
    void operator delete (void *ptr);\
    PLUGIN_NEW_NOTHROW\
    PLUGIN_DELETE_NOTHROW


// DEFINE

#if defined (ACE_HAS_NEW_NOTHROW)
#   define PLUGIN_NEW_NOTHROW_IMPL(inherited_class)\
        void * inherited_class::operator new (size_t bytes, const ACE_nothrow_t&)\
        {\
          return ::new (ACE_nothrow) char[bytes];\
        }
#   if !defined (ACE_LACKS_PLACEMENT_OPERATOR_DELETE)
#       define PLUGIN_DELETE_NOTHROW_IMPL(inherited_class)\
            void inherited_class::operator delete (void *p, const ACE_nothrow_t&) throw ()\
            {\
                delete [] static_cast <char *> (p);\
            }
#   else
#       define PLUGIN_DELETE_NOTHROW_IMPL
#   endif /* ACE_LACKS_PLACEMENT_OPERATOR_DELETE */
#endif

#define PLUGIN_MEM_DEFINE(export_macro, inherited_class, abstract_ns, abstract_class)\
    void * inherited_class::operator new (size_t bytes)\
    {\
        return ::new char[bytes];\
    }\
    void inherited_class::operator delete (void *ptr)\
    {\
        delete [] static_cast <char *> (ptr);\
    }\
    PLUGIN_NEW_NOTHROW_IMPL(inherited_class)\
    PLUGIN_DELETE_NOTHROW_IMPL(inherited_class)\
    extern "C" export_macro abstract_ns::abstract_class *create_##abstract_class ();\
    abstract_ns::abstract_class * create_##abstract_class ()\
    {\
        abstract_ns::abstract_class * p = 0;\
        ACE_NEW_RETURN (p, inherited_class, 0);\
        return p;\
    }

#endif // __PLUGIN_MACROS_H__
