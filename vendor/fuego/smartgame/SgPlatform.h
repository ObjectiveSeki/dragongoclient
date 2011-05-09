//----------------------------------------------------------------------------
/** @file SgPlatform.h */
//----------------------------------------------------------------------------

#ifndef SG_PLATFORM_H
#define SG_PLATFORM_H

#include <cstddef>

//----------------------------------------------------------------------------

/** Get information about the current computer. */
namespace SgPlatform
{

    /** Get total amount of memory available on the system.
        @return The total memory in bytes or 0 if the memory cannot be
        determined. */
    std::size_t TotalMemory();

}

//----------------------------------------------------------------------------

#endif // SG_PLATFORM_H
