#ifndef GET_PLUGIN_FUNCTION
#define GET_PLUGIN_FUNCTION

#include "ace/DLL.h"
#include "ace/Log_Msg.h"

template<class CREATOR, class PLUGIN_TYPE>
bool get_plugin(ACE_DLL & dll, ACE_TCHAR * plugin_creator_id, PLUGIN_TYPE ** ppPlugin)
{
    // Cast the void* to non-pointer type first - it's not legal to
    // cast a pointer-to-object directly to a pointer-to-function.
    void *void_ptr = dll.symbol (ACE_TEXT (plugin_creator_id));
    ptrdiff_t tmp = reinterpret_cast<ptrdiff_t> (void_ptr);
    CREATOR mc = reinterpret_cast<CREATOR> (tmp);
    if (mc == 0)
    {
        ACE_ERROR_RETURN ((LM_ERROR,
            "%p",
            "dll.symbol"),
            false);
    }

    *ppPlugin = mc();

    if (*ppPlugin == 0)
    {
        return false;
    }

    return true;
}

#endif  // GET_PLUGIN_FUNCTION


