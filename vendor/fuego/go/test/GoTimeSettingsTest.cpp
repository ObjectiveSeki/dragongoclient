//----------------------------------------------------------------------------
/** @file GoTimeSettingsTest.cpp
    Unit tests for GoTimeSettings. */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "GoTimeSettings.h"

#include <boost/test/auto_unit_test.hpp>

using namespace std;

//----------------------------------------------------------------------------

namespace {

BOOST_AUTO_TEST_CASE(GoTimeSettingsTest_DefaultConstructor)
{
    GoTimeSettings timeSettings;
    BOOST_CHECK(timeSettings.IsUnknown());
}

} // namespace

//----------------------------------------------------------------------------

