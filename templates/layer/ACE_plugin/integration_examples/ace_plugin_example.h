
// In xyz.h:

// Include ACE memory management for plugin                                         // <--
#include "cpp_abstract_class/plugin_macros.h"

// Include the plugin interface (abstract class)                                    // <--
#include "cpp_abstract_class/cpp_abstract_class.h"


    // Inherit from Cpp_abstract_class                                              // <--
    class Xyz : public Cpp_abstract_class_ns::Cpp_abstract_class
    {
    public:

        // Add default constructor                                                  // <--
        Xyz() {}

        // Add methods of abstract base class                                       // <--
        virtual void fn();
        virtual void get_version(int & major, int & minor, int & patch);

        // Add new/delete plugin methods                                            // <--
        PLUGIN_MEM_DECLARE;

        // Remove any unuseful stuff inherited from layer
    };

