// In file using Xyz as a plugin...

// Because the library is now loaded at runtime.
//
//      - remove the header of the library
//      - remove the namespace of the library
//      - remove any reference on functions or objects of the library
//


// Include abstract class header
#include "cpp_abstract_class/cpp_abstract_class.h"

// Include get_plugin function header
#include "cpp_abstract_class/get_plugin.h"

// Add this kind of code...
    try
    {
        ACE_DLL dll;

        int retval = dll.open (ACE_DLL_PREFIX ACE_TEXT("Xyz"));

        if (retval != 0)
        {
            ACE_ERROR_RETURN ((LM_ERROR,
                            "%p",
                            "dll.open"),
                            false);
        }

        typedef Cpp_abstract_class_ns::Cpp_abstract_class * (*Cpp_abstract_class_creator) (void);
        Cpp_abstract_class_ns::Cpp_abstract_class * pXyz = 0;
        if (get_plugin<Cpp_abstract_class_creator, Cpp_abstract_class_ns::Cpp_abstract_class>(dll, "create_Cpp_abstract_class", &pXyz))
        {
            pXyz->fn();
        }

        delete pXyz;

        dll.close ();
    }
    catch(const std::exception &exception)
    {
        printf("Unhandled error: %s", exception.what());
    }

