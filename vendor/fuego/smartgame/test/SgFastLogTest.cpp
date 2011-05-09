//----------------------------------------------------------------------------
/** @file SgFastLogTest.cpp
    Unit tests for SgFastLog. */
//----------------------------------------------------------------------------

#include "SgSystem.h"

#include <cmath>
#include <boost/test/auto_unit_test.hpp>
#include <boost/test/floating_point_comparison.hpp>
#include "SgFastLog.h"

using namespace std;

//----------------------------------------------------------------------------

namespace {

BOOST_AUTO_TEST_CASE(SgFastLogTest_Basic)
{
    SgFastLog fastLog(10);
    const float epsilon = 0.1f;
    const float naturalLogBase = exp(1.f);
    BOOST_CHECK_CLOSE(fastLog.Log(1), 0.0f, epsilon);
    BOOST_CHECK_CLOSE(fastLog.Log(naturalLogBase), 1.0f, epsilon);
    BOOST_CHECK_CLOSE(fastLog.Log(powf(naturalLogBase, 2.0f)), 2.0f, epsilon);
}

} // namespace

//----------------------------------------------------------------------------
