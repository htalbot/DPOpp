
// In file using xyz.cpp

// Implement Cpp_abstract_class                                                 // <--
void Xyz::get_version(int & major, int & minor, int & patch)
{
    major = XYZ_MAJOR;
    minor = XYZ_MINOR;
    patch = XYZ_PATCH;
}

void Xyz::fn()
{
    printf("Xyz::fn()\n");
}

// Implement memory management and factory stuff                                // <--
PLUGIN_MEM_DEFINE(XYZ_Export, Xyz, Cpp_abstract_class_ns, Cpp_abstract_class)

