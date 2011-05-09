//----------------------------------------------------------------------------
/** @file SgUctValueTest.cpp
    Unit tests for SgUctValue and SgUctValueUtil. */
//----------------------------------------------------------------------------

#include "SgSystem.h"

#include <boost/test/auto_unit_test.hpp>
#include "SgUctValue.h"

using namespace std;

//----------------------------------------------------------------------------

namespace {

/** Test for SgUctValueUtil::IsPrecise() */
BOOST_AUTO_TEST_CASE(SgUctValueTest_IsPrecise)
{
    using SgUctValueUtil::IsPrecise;
    {
        BOOST_CHECK(IsPrecise<double>(1.0));
        BOOST_CHECK(! IsPrecise<double>(numeric_limits<double>::max()));
        const int radix = std::numeric_limits<double>::radix;
        const int digits = std::numeric_limits<double>::digits;
        double count = pow(double(radix), digits) - 1;
        BOOST_CHECK(IsPrecise<double>(count));
        ++count;
        BOOST_CHECK(! IsPrecise<double>(count));
    }
    {
        BOOST_CHECK(IsPrecise<float>(1.0));
        BOOST_CHECK(! IsPrecise<float>(numeric_limits<float>::max()));
        const int radix = std::numeric_limits<float>::radix;
        const int digits = std::numeric_limits<float>::digits;
        float count = pow(float(radix), digits) - 1;
        BOOST_CHECK(IsPrecise<float>(count));
        ++count;
        BOOST_CHECK(! IsPrecise<float>(count));
    }
}

} // namespace

//----------------------------------------------------------------------------

